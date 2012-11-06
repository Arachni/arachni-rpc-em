=begin

    This file is part of the Arachni-RPC EM project and may be subject to
    redistribution and commercial restrictions. Please see the Arachni-RPC EM
    web site for more information on licensing and terms of use.

=end

module Arachni
module RPC
module EM

#
# Simple EventMachine-based RPC client.
#
# It's capable of:
# - performing and handling a few thousands requests per second (depending on
#   call size, network conditions and the like)
# - TLS encryption
# - asynchronous and synchronous requests
# - handling remote asynchronous calls that require a block
#
# @author: Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Client
    include ::Arachni::RPC::Exceptions

    #
    # Handles EventMachine's connection and RPC related stuff.
    #
    # It's responsible for TLS, storing and calling callbacks as well as
    # serializing, transmitting and receiving objects.
    #
    # @author: Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    #
    class Handler < EventMachine::Connection
        include ::Arachni::RPC::EM::Protocol
        include ::Arachni::RPC::EM::ConnectionUtilities

        DEFAULT_TRIES = 9

        def initialize( opts )
            @opts = opts.dup

            @max_retries = @opts[:max_retries] || DEFAULT_TRIES

            @opts[:tries] ||= 0
            @tries ||= @opts[:tries]

            @status = :idle

            @request = nil
            assume_client_role!
        end

        def post_init
            @status = :active
            start_ssl
        end

        def unbind( reason )
            end_ssl

            if @request && @request.callback && !done?
                if retry? #&& reason == Errno::ECONNREFUSED
                    retry_request
                else
                    e = Arachni::RPC::Exceptions::ConnectionError.new( "Connection closed [#{reason}]" )
                    @request.callback.call( e )
                end
            end

            @status = :closed
        end

        def connection_completed
            @status = :established
        end

        def status
            @status
        end

        def done?
            !!@done
        end

        #
        # Used to handle responses.
        #
        # @param    [Arachni::RPC::EM::Response]    res
        #
        def receive_response( res )
            if exception?( res )
                res.obj = Arachni::RPC::Exceptions.from_response( res )
            end

            @request.callback.call( res.obj ) if @request.callback

            @done = true
            @status = :done
            close_connection
        end

        def retry_request
            opts = @opts.dup
            opts[:tries] += 1

            @tries += 1
            ::EM.next_tick {
                ::EM::Timer.new( 0.2 ) {
                    ::EM.connect( opts[:host], opts[:port], self.class, opts ).
                        send_request( @request )
                    #reconnect( @opts[:host], @opts[:port].to_i ).send_request( @request )
                }
            }
        end

        def retry?
            @tries < @max_retries
        end

        # @param    [Arachni::RPC::EM::Response]    res
        def exception?( res )
            res.obj.is_a?( Hash ) && res.obj['exception'] ? true : false
        end

        #
        # Sends the request.
        #
        # @param    [Arachni::RPC::EM::Request]      req
        #
        def send_request( req )
            @request = req
            super( req )
            @status = :pending
        end
    end

    #
    # Options hash
    #
    # @return   [Hash]
    #
    attr_reader :opts

    #
    # Starts EventMachine and connects to the remote server.
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
    #
    def initialize( opts )
        @opts  = opts.merge( role: :client )
        @token = @opts[:token]

        @host, @port = @opts[:host], @opts[:port].to_i

        Arachni::RPC::EM.ensure_em_running
    end

    #
    # Calls a remote method and grabs the result.
    #
    # There are 2 ways to perform a call, async (non-blocking) and sync (blocking).
    #
    # To perform an async call you need to provide a block which will be passed
    # the return value once the method has finished executing.
    #
    #    server.call( 'handler.method', arg1, arg2 ) do |res|
    #        do_stuff( res )
    #    end
    #
    #
    # To perform a sync (blocking) call do not pass a block, the value will be
    # returned as usual.
    #
    #    res = server.call( 'handler.method', arg1, arg2 )
    #
    # @param    [String]    msg     in the form of <i>handler.method</i>
    # @param    [Array]     args    collection of arguments to be passed to the method
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

    private

    def connect
        ::EM.connect( @host, @port, Handler, @opts )
    end

    def call_async( req, &block )
        ::EM.next_tick {
            req.callback = block if block_given?
            connect.send_request( req )
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
