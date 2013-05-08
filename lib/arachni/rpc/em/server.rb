=begin

    This file is part of the Arachni-RPC EM project and may be subject to
    redistribution and commercial restrictions. Please see the Arachni-RPC EM
    web site for more information on licensing and terms of use.

=end

module Arachni
module RPC
module EM

require_relative 'server/handler'

#
# EventMachine-based RPC server class.
#
# It's capable of:
# - performing and handling a few thousands requests per second (depending on call size, network conditions and the like)
# - TLS encryption
# - asynchronous and synchronous requests
# - handling asynchronous methods that require a block
#
# @author: Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Server
    include ::Arachni::RPC::Exceptions

    attr_reader :token
    attr_reader :opts
    attr_reader :logger

    #
    # Starts EventMachine and the RPC server.
    #
    # opts example:
    #
    #    {
    #        :host  => 'localhost',
    #        :port  => 7331,
    #
    #        # optional authentication token, if it doesn't match the one
    #        # set on the server-side you'll be getting exceptions.
    #        :token => 'superdupersecret',
    #
    #        # optional serializer (defaults to YAML)
    #        # see the 'serializer' method at:
    #        # http://eventmachine.rubyforge.org/EventMachine/Protocols/ObjectProtocol.html#M000369
    #        :serializer => Marshal,
    #
    #        # serializer to use if the first choice fails
    #        :fallback_serializer => YAML,
    #
    #        #
    #        # In order to enable peer verification one must first provide
    #        # the following:
    #        #
    #        # SSL CA certificate
    #        :ssl_ca     => cwd + '/../spec/pems/cacert.pem',
    #        # SSL private key
    #        :ssl_pkey   => cwd + '/../spec/pems/client/key.pem',
    #        # SSL certificate
    #        :ssl_cert   => cwd + '/../spec/pems/client/cert.pem'
    #    }
    #
    # @param    [Hash]  opts
    #
    def initialize( opts )
        @opts  = opts

        if @opts[:ssl_pkey] && @opts[:ssl_cert]
            if !File.exist?( @opts[:ssl_pkey] )
                raise 'Could not find private key at: ' + @opts[:ssl_pkey]
            end

            if !File.exist?( @opts[:ssl_cert] )
                raise 'Could not find certificate at: ' + @opts[:ssl_cert]
            end
        end

        @token = @opts[:token]

        @logger = ::Logger.new( STDOUT )
        @logger.level = Logger::INFO

        @host, @port = @opts[:host], @opts[:port]

        clear_handlers
    end

    #
    # This is a way to identify methods that pass their result to a block
    # instead of simply returning them (which is the most usual operation of async methods.
    #
    # So no need to change your coding conventions to fit the RPC stuff,
    # you can just decide dynamically based on the plethora of data which Ruby provides
    # by its 'Method' class.
    #
    #    server.add_async_check do |method|
    #        #
    #        # Must return 'true' for async and 'false' for sync.
    #        #
    #        # Very simple check here...
    #        #
    #        'async' ==  method.name.to_s.split( '_' )[0]
    #    end
    #
    # @param    [Proc]  &block
    #
    def add_async_check( &block )
        @async_checks << block
    end

    #
    # Adds a handler by name:
    #
    #    server.add_handler( 'myclass', MyClass.new )
    #
    # @param    [String]    name    name via which to make the object available over RPC
    # @param    [Object]    obj     object instance
    #
    def add_handler( name, obj )
        @objects[name] = obj
        @methods[name] = Set.new # no lookup overhead please :)
        @async_methods[name] = Set.new

        obj.class.public_instance_methods( false ).each do |method|
            @methods[name] << method.to_s
            @async_methods[name] << method.to_s if async_check( obj.method( method ) )
        end
    end

    #
    # Clears all handlers and their associated information like methods
    # and async check blocks.
    #
    def clear_handlers
        @objects = {}
        @methods = {}

        @async_checks  = []
        @async_methods = {}
    end

    #
    # Runs the server and blocks.
    #
    def run
        Arachni::RPC::EM.schedule { start }
        Arachni::RPC::EM.block
    end

    #
    # Starts the server but does not block.
    #
    def start
        @logger.info( 'System' ){ "RPC Server started." }
        @logger.info( 'System' ){ "Listening on #{@host}:#{@port}" }

        ::EM.start_server( @host, @port, Handler, self )
    end

    def call( connection )

        req = connection.request
        peer_ip_addr = connection.peer_ip_addr

        expr, args = req.message, req.args
        meth_name, obj_name = parse_expr( expr )

        log_call( peer_ip_addr, expr, *args )

        if !object_exist?( obj_name )
            msg = "Trying to access non-existent object '#{obj_name}'."
            @logger.error( 'Call' ){ msg + " [on behalf of #{peer_ip_addr}]" }
            raise InvalidObject.new( msg )
        end

        if !public_method?( obj_name, meth_name )
            msg = "Trying to access non-public method '#{meth_name}'."
            @logger.error( 'Call' ){ msg + " [on behalf of #{peer_ip_addr}]" }
            raise InvalidMethod.new( msg )
        end

        # the proxy needs to know whether this is an async call because if it
        # is we'll have already send the response.
        res = Response.new
        res.async! if async?( obj_name, meth_name )

        if !res.async?
            res.obj = @objects[obj_name].send( meth_name.to_sym, *args )
        else
            @objects[obj_name].send( meth_name.to_sym, *args ) do |obj|
                res.obj = obj
                connection.send_response( res )
            end
        end

        res
    end

    #
    # @return   [TrueClass]
    #
    def alive?
        true
    end

    #
    # Shuts down the server after 2 seconds
    #
    def shutdown
        wait_for = 2

        @logger.info( 'System' ){ "Shutting down in #{wait_for} seconds..." }

        # don't die before returning
        ::EM.add_timer( wait_for ) { ::EM.stop }
        true
    end

    private

    def async?( objname, method )
        @async_methods[objname].include?( method )
    end

    def async_check( method )
        @async_checks.each { |check| return true if check.call( method ) }
        false
    end


    def log_call( peer_ip_addr, expr, *args )
        msg = "#{expr}"

        # this should be in a @logger.debug call but it'll get out of sync
        if @logger.level == Logger::DEBUG
            cargs = args.map { |arg| arg.inspect }
            msg += "( #{cargs.join( ', ' )} )"
        end

        msg += " [#{peer_ip_addr}]"

        @logger.info( 'Call' ){ msg }
    end

    def parse_expr( expr )
        parts = expr.to_s.split( '.' )
        # method name, object name
        [ parts.pop, parts.join( '.' ) ]
    end

    def object_exist?( obj_name )
        @objects[obj_name] ? true : false
    end

    def public_method?( obj_name, method )
        @methods[obj_name].include?( method )
    end

end

end
end
end
