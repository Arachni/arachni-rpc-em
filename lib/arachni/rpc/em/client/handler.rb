=begin

    This file is part of the Arachni-RPC EM project and may be subject to
    redistribution and commercial restrictions. Please see the Arachni-RPC EM
    web site for more information on licensing and terms of use.

=end

module Arachni
module RPC::EM
class Client

#
# Client connection handler.
#
# @author: Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Handler < EventMachine::Connection
    include Protocol
    include ConnectionUtilities

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
                e = RPC::Exceptions::ConnectionError.new( "Connection closed [#{reason}]" )
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
            res.obj = RPC::Exceptions.from_response( res )
        end

        @request.callback.call( res.obj ) if @request.callback
    ensure
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

end
end
end
