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
# Helper methods to be included in EventMachine::Connection classes
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
module ConnectionUtilities

    #
    # @return   [String]    IP address of the client
    #
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
