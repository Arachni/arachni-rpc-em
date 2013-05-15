=begin

    This file is part of the Arachni-RPC EM project and may be subject to
    redistribution and commercial restrictions. Please see the Arachni-RPC EM
    web site for more information on licensing and terms of use.

=end

module Arachni
module RPC
module EM

#
# Provides helper transport methods for `Arachni::RPC::Message` transmission.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
module Protocol
    include ::Arachni::RPC::EM::SSL

    # Send a maximum of 16kb of data per tick.
    MAX_CHUNK_SIZE = 1024 * 16

    #
    # Receives data from the network.
    #
    # Rhe data will be chunks of a serialized object which will be buffered
    # until the whole transmission has finished.
    #
    # It will then unserialize it and pass it to {#receive_object}.
    #
    def receive_data( data )
        # Break out early if the request is sent by an unverified peer and SSL
        # peer verification has been enabled.
        if ssl_opts? && !verified_peer? && @role == :server
            e = Arachni::RPC::Exceptions::SSLPeerVerificationFailed.new( 'Could not verify peer.' )
            send_response Response.new( :obj => {
                'exception' => e.to_s,
                'backtrace' => e.backtrace,
                'type'      => 'SSLPeerVerificationFailed'
            })

            log( :error, 'SSL', " Could not verify peer. ['#{peer_ip_addr}']." )
            return
        end

        (@buf ||= '') << data

        while @buf.size >= 4
            if @buf.size >= 4 + ( size = @buf.unpack( 'N' ).first )
                @buf.slice!( 0, 4 )
                receive_object( unserialize( @buf.slice!( 0, size ) ) )
            else
                break
            end
        end
    end

    private

    # Stub method, should be implemented by servers.
    #
    # @param    [Arachni::RPC::Request]     request
    # @abstract
    def receive_request( request )
        p request
    end

    #
    # Stub method, should be implemented by clients.
    #
    # @param    [Arachni::RPC::Response]    response
    # @abstract
    def receive_response( response )
        p response
    end

    #
    # Converts incoming hash objects to `Arachni::RPC::Request` and
    # `Arachni::RPC::Response` objects (depending on the assumed role) and calls
    # {#receive_request} or {#receive_response} accordingly.
    #
    # @param    [Hash]      obj
    #
    def receive_object( obj )
        if @role == :server
            receive_request( Request.new( obj ) )
        else
            receive_response( Response.new( obj ) )
        end
    end

    # @param    [Arachni::RPC::Message]    msg
    #   Message to send to the peer.
    def send_message( msg )
        ::EM.schedule { send_object( msg.prepare_for_tx ) }
    end
    alias :send_request  :send_message
    alias :send_response :send_message

    #
    # @note Will split the object in chunks of MAX_CHUNK_SIZE and transmit one
    #   at a time.
    #
    # @param    [Object]    obj  Object to send.
    def send_object( obj )
        data = serialize( obj )
        packed = [data.bytesize, data].pack( 'Na*' )

        while packed
            if packed.bytesize > MAX_CHUNK_SIZE
                send_data( packed.slice!( 0, MAX_CHUNK_SIZE ) )
            else
                send_data( packed )
                break
            end
        end
    end

    # Become a server.
    def assume_server_role!
        @role = :server
    end

    # Become a client.
    def assume_client_role!
        @role = :client
    end

    # Returns the preferred serializer based on the `serializer` option of the
    # server.
    #
    # @return   [.load, .dump]     Serializer to be used (Defaults to `YAML`).
    def serializer
        return @client_serializer if @client_serializer

        @opts[:serializer] ? @opts[:serializer] : YAML
    end

    def fallback_serializer
        @opts[:fallback_serializer] ? @opts[:serializer] : YAML
    end

    def serialize( obj )
        serializer.dump obj
    end

    def unserialize( obj )
        begin
            r = serializer.load( obj )

            if !r.is_a?( Hash ) && @opts[:fallback_serializer]
                r = @opts[:fallback_serializer].load( obj )
                @client_serializer = @opts[:fallback_serializer]
            end

            r
        rescue Exception => e
            raise if !@opts[:fallback_serializer]

            @client_serializer = @opts[:fallback_serializer]

            @opts[:fallback_serializer].load obj
        end
    end

end

end
end
end
