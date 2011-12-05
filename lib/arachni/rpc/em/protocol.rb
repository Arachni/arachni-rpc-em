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
# Provides helper transport methods for {Message} transmission.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
module Protocol
    include ::Arachni::RPC::EM::SSL

    # send a maximum of 16kb of data per tick
    MAX_CHUNK_SIZE = 1024 * 16

    # become a server
    def assume_server_role!
        @role = :server
    end

    # become a client
    def assume_client_role!
        @role = :client
    end

    #
    # Stub method, should be implemented by servers.
    #
    # @param    [Arachni::RPC::EM::Request]     request
    #
    def receive_request( request )
        p request
    end

    #
    # Stub method, should be implemented by clients.
    #
    # @param    [Arachni::RPC::EM::Response]    response
    #
    def receive_response( response )
        p response
    end

    #
    # Converts incoming hash objects to Requests or Response
    # (depending on the assumed role) and calls receive_request() or receive_response()
    # accordingly.
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

    #
    # Sends a message to the peer.
    #
    # @param    [Arachni::RPC::EM::Message]    msg
    #
    def send_message( msg )
        ::EM.schedule {
            send_object( msg.prepare_for_tx )
        }
    end
    alias :send_request  :send_message
    alias :send_response :send_message

    #
    # Receives data from the network.
    #
    # In this case the data will be chunks of a serialized object which
    # will be buffered until the whole transmission has finished.
    #
    # It will then unresialize it and pass it to receive_object().
    #
    def receive_data( data )
        #
        # cut them out as soon as possible
        #
        # don't buffer any data from unverified peers if SSL peer
        # veification has been enabled
        #
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
                receive_object( serializer.load( @buf.slice!( 0, size ) ) )
            else
                break
            end
        end
    end

    #
    # Sends a ruby object over the network
    #
    # Will split the object in chunks of MAX_CHUNK_SIZE and transmit one at a time.
    #
    def send_object( obj )
        data = serializer.dump( obj )
        packed = [data.bytesize, data].pack( 'Na*' )

        while( packed )
            if packed.bytesize > MAX_CHUNK_SIZE
                send_data( packed.slice!( 0, MAX_CHUNK_SIZE ) )
            else
                send_data( packed )
                break
            end
        end
    end

    #
    # Returns the preferred serializer based on the 'serializer' option of the server.
    #
    # Defaults to <i>YAML</i>.
    #
    # @return   [Class]     serializer to be used
    #
    # @see http://eventmachine.rubyforge.org/EventMachine/Protocols/ObjectProtocol.html#M000369
    #
    def serializer
        @opts[:serializer] ? @opts[:serializer] : YAML
    end

end

end
end
end
