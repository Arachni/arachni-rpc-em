=begin
                  Arachni-RPC
  Copyright (c) 2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module RPC

#
# Provides some convenient methods for EventMachine's Reactor.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
module EM

module Synchrony

    def run( &block )
        @@root_f = Fiber.new {
            block.call
        }.resume
    end

    extend self

end

    #
    # Inits method variables for the Reactor tasks and its Mutex.
    #
    def init
        @@reactor_tasks_mutex ||= Mutex.new
        @@reactor_tasks ||= []
    end

    #
    # Adds a block in the Reactor.
    #
    # @param    [Proc]    &block    block to be included in the Reactor loop
    #
    def add_to_reactor( &block )

        self.init

        # if we're already in the Reactor thread just run the block straight up.
        if ::EM::reactor_thread?
            block.call
        else
            @@reactor_tasks_mutex.lock
            @@reactor_tasks << block

            ensure_em_running!
            @@reactor_tasks_mutex.unlock
        end

    end

    #
    # Blocks until the Reactor stops running
    #
    def block!
        # beware of deadlocks, we can't join our own thread
        ::EM.reactor_thread.join if ::EM.reactor_thread && !::EM::reactor_thread?
    end

    #
    # Puts the Reactor in its own thread and runs it.
    #
    # It also runs all blocks sent to {#add_to_reactor}.
    #
    def ensure_em_running!
        self.init

        if !::EM::reactor_running?
            q = Queue.new

            Thread.new do
                ::EM::run do

                    ::EM.error_handler do |e|
                        $stderr.puts "Exception raised during event loop: " +
                        "#{e.message} (#{e.class})\n#{(e.backtrace ||
                            [])[0..5].join("\n")}"
                    end

                    @@reactor_tasks.each { |task| task.call }
                    q << true
                end
            end
            q.pop
        end
    end

    extend self
end
end
end
