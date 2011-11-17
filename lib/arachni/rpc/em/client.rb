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
# Simple EventMachine-based RPC client.
#
# It's capable of:
# - performing and handling a few thousands requests per second (depending on call size, network conditions and the like)
# - TLS encryption
# - asynchronous and synchronous requests
# - handling remote asynchronous calls that require a block
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class Client

    include ::Arachni::RPC::Exceptions

    #
    # Handles EventMachine's connection and RPC related stuff.
    #
    # It's responsible for TLS, storing and calling callbacks as well as
    # serializing, transmitting and receiving objects.
    #
    # @author: Tasos "Zapotek" Laskos
    #                                      <tasos.laskos@gmail.com>
    #                                      <zapotek@segfault.gr>
    # @version: 0.1
    #
    class Handler < EventMachine::Connection
        include ::Arachni::RPC::EM::Protocol
        include ::Arachni::RPC::EM::ConnectionUtilities

        def initialize( opts )
            @opts = opts
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

            if @request && @request.callback && @status != :done
                e = Arachni::RPC::Exceptions::ConnectionError.new( "Connection closed [#{reason}]" )
                @request.callback.call( e )
            end

            @status = :closed
        end

        def connection_completed
            @status = :established
        end

        def status
            @status
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

            if cb = @request.callback

                callback = Proc.new {
                    |obj|
                    cb.call( obj )

                    @status = :done
                    close_connection
                }

                if @request.defer?
                    # the callback might block a bit so tell EM to put it in a thread
                    ::EM.defer {
                        callback.call( res.obj )
                    }
                else
                    callback.call( res.obj )
                end
            end
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
            @status = :pending
            @request = req
            super( req )
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

        begin
            @opts  = opts.merge( :role => :client )
            @token = @opts[:token]

            @host, @port = @opts[:host], @opts[:port]

            Arachni::RPC::EM.ensure_em_running!
        rescue EventMachine::ConnectionError => e
            exc = ConnectionError.new( e.to_s + " for '#{@k}'." )
            exc.set_backtrace( e.backtrace )
            raise exc
        end
    end

    #
    # Calls a remote method and grabs the result.
    #
    # There are 2 ways to perform a call, async (non-blocking) and sync (blocking).
    #
    # To perform an async call you need to provide a block which will be passed
    # the return value once the method has finished executing.
    #
    #    server.call( 'handler.method', arg1, arg2 ){
    #        |res|
    #        do_stuff( res )
    #    }
    #
    #
    # To perform a sync (blocking) call do not pass a block, the value will be
    # returned as usual.
    #
    #    res = server.call( 'handler.method', arg1, arg2 )
    #
    # @param    [String]    msg     in the form of <i>handler.method</i>
    # @param    [Array]     args    collection of argumenta to be passed to the method
    # @param    [Proc]      &block
    #
    def call( msg, *args, &block )

        req = Request.new(
            :message  => msg,
            :args     => args,
            :callback => block,
            :token    => @token
        )

        if block_given?
            call_async( req )
        else
            return call_sync( req )
        end
    end

    private

    def connect
        ::EM.connect( @host, @port, Handler, @opts )
    end

    def call_async( req, &block )
        ::EM.schedule {
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
            call_async( req ) {
                |obj|
                t.wakeup
                ret = obj
            }
            sleep
        else
            # Fibers do not work across threads so don't defer the callback
            # once the Handler gets to it
            req.do_not_defer!

            f = Fiber.current
            call_async( req ) {
                |obj|
                f.resume( obj )
            }

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
        return ret
    end

end

end
end
end
