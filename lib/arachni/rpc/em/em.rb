=begin

    This file is part of the Arachni-RPC EM project and may be subject to
    redistribution and commercial restrictions. Please see the Arachni-RPC EM
    web site for more information on licensing and terms of use.

=end

module Arachni
module RPC

#
# Provides some convenient methods for EventMachine's Reactor.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
module EM

    module Synchrony
        def run( &block )
            Fiber.new{ block.call }.resume
        end

        extend self
    end

    # @note Will make sure EM is running first.
    #
    # @param    [Block]    block Block to be run in the EM reactor.
    def schedule( &block )
        ensure_em_running
        ::EM.schedule( &block )
    end

    # Blocks until the Reactor stops running
    def block
        # beware of deadlocks, we can't join our own thread
        ::EM.reactor_thread.join if ::EM.reactor_thread && !::EM::reactor_thread?
    end

    # Puts the Reactor in its own thread and runs it.
    def ensure_em_running
        if !::EM::reactor_running?

            Thread.new do
                ::EM.run do
                    ::EM.error_handler do |e|
                        $stderr.puts "Exception raised during event loop: " +
                        "#{e.message} (#{e.class})\n#{(e.backtrace ||
                            [])[0..5].join("\n")}"
                    end
                end
            end

            sleep 0.1 while !::EM.reactor_running?
        end
    end

    extend self
end
end
end
