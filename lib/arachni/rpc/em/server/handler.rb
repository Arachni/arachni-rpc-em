=begin

    This file is part of the Arachni-RPC EM project and may be subject to
    redistribution and commercial restrictions. Please see the Arachni-RPC EM
    web site for more information on licensing and terms of use.

=end

module Arachni
module RPC::EM
class Server

#
# Server connection handler.
#
# @author: Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Handler < EventMachine::Connection
    include Protocol
    include ConnectionUtilities
    include ::Arachni::RPC::Exceptions

    INACTIVITY_TIMEOUT = 10

    attr_reader :request

    def initialize( server )
        super
        @server = server
        @opts   = server.opts

        assume_server_role!

        @id = nil
        @request = nil

        # Do not tolerate long periods of inactivity in order to avoid zombie
        # connections.
        set_comm_inactivity_timeout( INACTIVITY_TIMEOUT )
    end

    # starts TLS
    def post_init
        start_ssl
    end

    def unbind
        end_ssl
        @server = nil
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
        res  = ::Arachni::RPC::Response.new
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

        #
        # pass the result of the RPC call back to the client
        # along with the callback ID but *only* if it wan't async
        # because server.call() will have already taken care of it
        #
        send_response( res ) if !res.async?
    end

    #
    # Authenticates the client based on the token in the request.
    #
    # It will raise an exception if the token doesn't check-out.
    #
    def authenticate!
        if !valid_token?( @request.token )

            msg = 'Token missing or invalid while calling: ' + @request.message

            @server.logger.error( 'Authenticator' ){
                msg + " [on behalf of #{peer_ip_addr}]"
            }

            fail InvalidToken.new( msg )
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
end
end
end
