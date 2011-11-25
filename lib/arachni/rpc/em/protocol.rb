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
    include ::EM::P::ObjectProtocol
    include ::Arachni::RPC::EM::SSL

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