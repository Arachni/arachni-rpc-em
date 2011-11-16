=begin
                  Arachni-RPC
  Copyright (c) 2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module RPC
module EM

#
# EventMachine-based RPC server class.
#
# It's capable of:
# - performing and handling a few thousands requests per second (depending on call size, network conditions and the like)
# - TLS encryption
# - asynchronous and synchronous requests
# - handling asynchronous methods that require a block
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class Server

    include ::Arachni::RPC::Exceptions

    #
    # Handles EventMachine's connection stuff.
    #
    # It's responsible for TLS, serializing, transmitting and receiving objects,
    # as well as authenticating the client using the token.
    #
    # It also handles and forwards exceptions.
    #
    # @author: Tasos "Zapotek" Laskos
    #                                      <tasos.laskos@gmail.com>
    #                                      <zapotek@segfault.gr>
    # @version: 0.1
    #
    class Proxy < EventMachine::Connection

        include ::Arachni::RPC::EM::Protocol
        include ::Arachni::RPC::Exceptions
        include ::Arachni::RPC::EM::ConnectionUtilities

        INACTIVITY_TIMEOUT = 10

        attr_reader :request

        def initialize( server )
            super
            @server = server
            @opts   = server.opts

            assume_server_role!

            @id = nil
            @request = nil

            # do not tolerate long periods of
            # inactivity in order to avoid zombie connections
            set_comm_inactivity_timeout( INACTIVITY_TIMEOUT )
        end

        # starts TLS
        def post_init
            start_ssl
        end

        def unbind
            end_ssl
        end

        def log( severity, progname, msg )
            sev_sym = Logger.const_get( severity.to_s.upcase.to_sym )
            @server.logger.add( sev_sym, msg, progname )
        end

        #
        # Handles requests and sends back the responses.
        #
        # @param    [Arachni::RPC::EM::Request]     req
        #
        def receive_request( req )
            @request = req

            # the method call may block a little so tell EventMachine to
            # stick it in its own thread.
            # ::EM.defer( proc {
                res  = Response.new
                peer = peer_ip_addr

                begin
                    # token-based authentication
                    authenticate!

                    # grab the result of the method call
                    res.merge!( @server.call( self ) )

                # handle exceptions and convert them to a simple hash,
                # ready to be passed to the client.
                rescue Exception => e

                    type = ''

                    # if it's an RPC exception pass the type along as is
                    if e.rpc_exception?
                        type = e.class.name.split( ':' )[-1]

                    # otherwise set it to a RemoteExeption
                    else
                        type = 'RemoteException'
                    end

                    res.obj = {
                        'exception' => e.to_s,
                        'backtrace' => e.backtrace,
                        'type'      => type
                    }

                    msg = "#{e.to_s}\n#{e.backtrace.join( "\n" )}"
                    @server.logger.error( 'Exception' ){ msg + " [on behalf of #{peer}]" }
                end

                # res
            # }, proc {
                # |res|

                #
                # pass the result of the RPC call back to the client
                # along with the callback ID but *only* if it wan't async
                # because server.call() will have already taken care of it
                #
                send_response( res ) if !res.async?
            # })
        end

        #
        # Authenticates the client based on the token in the request.
        #
        # It will raise an exception if the token doesn't check-out.
        #
        # @param    [String]    peer    IP address of the client
        # @param    [Hash]      req     request
        #
        def authenticate!
            if !valid_token?( @request.token )

                msg = 'Token missing or invalid while calling: ' +
                    @req['message']

                @server.logger.error( 'Authenticator' ){
                    msg + " [on behalf of #{peer_ip_addr}]"
                }

                raise( InvalidToken.new( msg ) )
            end
        end

        #
        # Compares the authentication token in the param with the one of the server.
        #
        # @param    [String]    token
        #
        # @return   [Bool]
        #
        def valid_token?( token )
            token == @server.token
        end

    end

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
    #    server.add_async_check {
    #        |method|
    #        #
    #        # Must return 'true' for async and 'false' for sync.
    #        #
    #        # Very simple check here...
    #        #
    #        'async' ==  method.name.to_s.split( '_' )[0]
    #    }
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

        obj.class.public_instance_methods( false ).each {
            |method|
            @methods[name] << method.to_s
            @async_methods[name] << method.to_s if async_check( obj.method( method ) )
        }
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
        Arachni::RPC::EM.add_to_reactor {
            start
        }
        Arachni::RPC::EM.block!
    end

    #
    # Starts the server but does not block.
    #
    def start
        @logger.info( 'System' ){ "RPC Server started." }
        @logger.info( 'System' ){ "Listening on #{@host}:#{@port}" }

        ::EM.start_server( @host, @port, Proxy, self )
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
            raise( InvalidObject.new( msg ) )
        end

        if !public_method?( obj_name, meth_name )
            msg = "Trying to access non-public method '#{meth_name}'."
            @logger.error( 'Call' ){ msg + " [on behalf of #{peer_ip_addr}]" }
            raise( InvalidMethod.new( msg ) )
        end

        # the proxy needs to know whether this is an async call because if it
        # is we'll have already send the response.
        res = Response.new
        res.async! if async?( obj_name, meth_name )

        if !res.async?
            res.obj = @objects[obj_name].send( meth_name.to_sym, *args )
        else
            @objects[obj_name].send( meth_name.to_sym, *args ){
                |obj|
                res.obj = obj
                connection.send_response( res )
            }
        end

        return res
    end

    #
    # @return   [TrueClass]
    #
    def alive?
        return true
    end

    #
    # Shuts down the server after 2 seconds
    #
    def shutdown
        wait_for = 2

        @logger.info( 'System' ){ "Shutting down in #{wait_for} seconds..." }

        # don't die before returning
        EventMachine::add_timer( wait_for ) { ::EM.stop }
        return true
    end

    private

    def async?( objname, method )
        @async_methods[objname].include?( method )
    end

    def async_check( method )
        @async_checks.each {
            |check|
            return true if check.call( method )
        }
        return false
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
