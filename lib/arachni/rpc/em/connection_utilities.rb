=begin

    This file is part of the Arachni-RPC EM project and may be subject to
    redistribution and commercial restrictions. Please see the Arachni-RPC EM
    web site for more information on licensing and terms of use.

=end

module Arachni
module RPC
module EM

#
# Helper methods to be included in EventMachine::Connection classes
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
module ConnectionUtilities

    # @return   [String]    IP address of the client
    def peer_ip_addr
        begin
            if peername = get_peername
                Socket.unpack_sockaddr_in( peername )[1]
            else
                'n/a'
            end
        rescue
            'n/a'
        end
    end

end

end
end
end
