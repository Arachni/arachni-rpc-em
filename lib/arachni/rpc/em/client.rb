=begin

    This file is part of the Arachni-RPC EM project and may be subject to
    redistribution and commercial restrictions. Please see the Arachni-RPC EM
    web site for more information on licensing and terms of use.

=end

module Arachni
module RPC
module EM

require_relative 'client/handler'

#
# Simple EventMachine-based RPC client.
#
# It's capable of:
#
# * Performing and handling a few thousands requests per second (depending on
#       call size, network conditions and the like)
# * TLS encryption
# * Asynchronous and synchronous requests
# * Handling remote asynchronous calls that require a block
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Client
    include ::Arachni::RPC::Exceptions

    # Default amount of connections to maintain in the re-use pool.
    DEFAULT_CONNECTION_POOL_SIZE = 50

    # @return   [Hash]  Options hash.
    attr_reader :opts

    #
    # Starts EventMachine and connects to the remote server.
    #
    # @example Example options:
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
    #        :max_retries => 0,
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
    # @option   opts    [String]    :host   Hostname/IP address.
    # @option   opts    [Integer]   :port   Port number.
    # @option   opts    [String]    :token  Optional authentication token.
    # @option   opts    [#dump, #load]      :serializer (YAML)
    #   Serializer to use for message transmission.
    # @option   opts    [#dump, #load]      :fallback_serializer
    #   Optional fallback serializer to be used when the primary one fails.
    # @option   opts    [Integer]   :max_retries
    #   How many times to retry failed requests.
    # @option   opts    [String]    :ssl_ca  SSL CA certificate.
    # @option   opts    [String]    :ssl_pkey  SSL private key.
    # @option   opts    [String]    :ssl_cert  SSL certificate.
    #
    def initialize( opts )
        @opts  = opts.merge( role: :client )
        @token = @opts[:token]

        @host, @port = @opts[:host], @opts[:port].to_i
        @pool_size   = @opts[:connection_pool_size] || DEFAULT_CONNECTION_POOL_SIZE

        @connections ||= []

        Arachni::RPC::EM.ensure_em_running
    end

    #
    # Calls a remote method and grabs the result.
    #
    # There are 2 ways to perform a call, async (non-blocking) and sync (blocking).
    #
    # @example  To perform an async call you need to provide a block to handle the result.
    #
    #    server.call( 'handler.method', arg1, arg2 ) do |res|
    #        do_stuff( res )
    #    end
    #
    #
    # @example  To perform a sync (blocking), call without a block.
    #
    #    res = server.call( 'handler.method', arg1, arg2 )
    #
    # @param    [String]    msg
    #   RPC message in the form of `handler.method`.
    # @param    [Array]     args
    #   Collection of arguments to be passed to the method.
    # @param    [Proc]      &block
    #
    def call( msg, *args, &block )
        req = Request.new(
            message:  msg,
            args:     args,
            callback: block,
            token:    @token
        )

        block_given? ? call_async( req ) : call_sync( req )
    end

    # {Handler#done? Finished} {Handler}s push themselves here to be re-used.
    #
    # @param    [Handler]   connection
    def push_connection( connection )
        return if @pool_size <= 0 || @connections.size > @pool_size
        @connections << connection
    end

    private

    def connect
        # Some connections may have died while they wait in the queue,
        # get rid of them.
        @connections.reject! { |c| !c.done? }

        return @connections.pop if @connections.any?
        ::EM.connect( @host, @port, Handler, @opts.merge( client: self ) )
    end

    def call_async( req, &block )
        ::EM.next_tick {
            req.callback = block if block_given?

            begin
                connect.send_request( req )
            rescue ::EM::ConnectionError => e
                exc = ConnectionError.new( e.to_s + " for '#{@host}:#{@port}'." )
                exc.set_backtrace( e.backtrace )
                req.callback.call exc
            end
        }
    end

    def call_sync( req )
        ret = nil

        # if we're in the Reactor thread use a Fiber and if we're not
        # use a Thread
        if !::EM::reactor_thread?
            t = Thread.current
            call_async( req ) do |obj|
                t.wakeup
                ret = obj
            end
            sleep
        else
            f = Fiber.current
            call_async( req ) { |obj| f.resume( obj ) }

            begin
                ret = Fiber.yield
            rescue FiberError => e
                msg = e.to_s + "\n"
                msg += '(Consider wrapping your sync code in a' +
                    ' "::Arachni::RPC::EM::Synchrony.run" ' +
                    'block when your app is running inside the Reactor\'s thread)'

                raise( msg )
            end
        end

        raise ret if ret.is_a?( Exception )
        ret
    end

end

end
end
end
