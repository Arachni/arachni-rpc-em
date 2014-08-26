=begin

    This file is part of the Arachni-RPC EM project and may be subject to
    redistribution and commercial restrictions. Please see the Arachni-RPC EM
    web site for more information on licensing and terms of use.

=end

module Arachni
module RPC::EM
class Client

#
# Transmits `Arachni::RPC::Request` objects and calls callbacks once an
# `Arachni::RPC::Response` is received.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
class Handler < EventMachine::Connection
    include Protocol
    include ConnectionUtilities

    # Default amount of tries for failed requests.
    DEFAULT_TRIES = 9

    # @return   [Symbol]    Status of the connection, can be:
    #
    # * `:idle` -- Just initialized.
    # * `:ready` -- A connection has been established.
    # * `:pending` -- Sending request and awaiting response.
    # * `:done` -- Response received and callback invoked -- ready to be reused.
    # * `:closed` -- Connection closed.
    attr_reader :status

    # Prepares an RPC connection and sets {#status} to `:idle`.
    #
    # @param    [Hash]  opts
    # @option   opts    [Integer]   :max_retries    (9)
    #   Default amount of tries for failed requests.
    #
    # @option   opts    [Client]   :base
    #   Client instance (needed to {Client#push_connection push} ourselves
    #   back to its connection pool once we're done and we're ready to be reused.)
    def initialize( opts )
        @opts = opts.dup

        @max_retries = @opts[:max_retries] || DEFAULT_TRIES

        @client = @opts[:client]

        @opts[:tries] ||= 0
        @tries ||= @opts[:tries]

        @status = :idle

        @request = nil
        assume_client_role!
    end

    # Sends an RPC request (i.e. performs an RPC call) and sets {#status}
    # to `:pending`.
    #
    # @param    [Arachni::RPC::Request]      req
    def send_request( req )
        @request = req
        @status  = :pending
        super( req )
    end

    # @note Pushes itself to the client's connection pool to be re-used.
    #
    # Handles responses to RPC requests, calls its callback and sets {#status}
    # to `:done`.
    #
    # @param    [Arachni::RPC::Response]    res
    #
    def receive_response( res )
        if exception?( res )
            res.obj = RPC::Exceptions.from_response( res )
        end

        @request.callback.call( res.obj ) if @request.callback
    ensure
        @request = nil # Help the GC out.
        @status  = :done
        @opts[:tries] = @tries = 0
        @client.push_connection self
    end

    # Initializes an SSL session once the connection has been established and
    # sets {#status} # to `:ready`.
    #
    # @private
    def post_init
        @status = :ready
        start_ssl
    end

    # Handles closed connections, cleans up the SSL session, retries (if
    # necessary) and sets {#status} to `:closed`.
    #
    # @private
    def unbind( reason )
        end_ssl

        # If there is a request and a callback and the callback hasn't yet be
        # called (i.e. not done) then we got here by error so retry.
        if @request && @request.callback && !done?
            if retry? #&& reason == Errno::ECONNREFUSED
                #p 'RETRY'
                #p @client.connection_count
                retry_request
            else
                #p 'FAIL'
                #p @client.connection_count
                e = RPC::Exceptions::ConnectionError.new( "Connection closed [#{reason}]" )
                @request.callback.call( e )
                @client.connection_failed self
            end
            return
        end

        close_without_retry
    end

    # @return   [Boolean]
    #   `true` when the connection has been closed, `false` otherwise.
    def closed?
        @status == :closed
    end

    # @note If `true`, the connection can be re-used.
    #
    # @return   [Boolean]
    #   `true` when the connection is done, `false` otherwise.
    def done?
        @status == :done
    end

    # Closes the connection without triggering a retry operation and sets
    # {#status} to `:closed`.
    def close_without_retry
        @request = nil
        @status  = :closed
        close_connection
    end

    private

    def retry_request
        opts = @opts.dup
        opts[:tries] += 1

        req = @request.dup

        @tries += 1
        ::EM.next_tick {
            ::EM::Timer.new( 0.2 ) {
                address = opts[:socket] ? opts[:socket] : [opts[:host], opts[:port]]
                ::EM.connect( *[address, self.class, opts ].flatten ).send_request( req )
            }
        }

        close_without_retry
    end

    def retry?
        @tries < @max_retries
    end

    # @param    [Arachni::RPC::Response]    res
    def exception?( res )
        res.obj.is_a?( Hash ) && res.obj['exception'] ? true : false
    end

end

end
end
end
