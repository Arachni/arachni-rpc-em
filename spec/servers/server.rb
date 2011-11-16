=begin
                  Arachni-RPC
  Copyright (c) 2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

$cwd = cwd = File.expand_path( File.dirname( __FILE__ ) )
require File.join( cwd, '../../lib/arachni/rpc/', 'em' )
require File.join( cwd, '../', 'spec_helper' )

class Parent
    def foo( arg )
        return arg
    end
end

class Test < Parent

    # in order to make inherited methods accessible you've got to explicitly
    # make them public
    private :foo
    public :foo

    #
    # Uses EventMachine to call the block asynchronously
    #
    def async_foo( arg, &block )
        ::EM.schedule {
            ::EM.defer {
                block.call( arg ) if block_given?
            }
        }
    end

end

def start_server( opts, do_not_start = false )

    server = Arachni::RPC::EM::Server.new( opts )

    server.add_async_check {
        |method|
        #
        # Must return 'true' for async and 'false' for sync.
        #
        # Very simple check here...
        #
        'async' ==  method.name.to_s.split( '_' )[0]
    }

    server.add_handler( 'test', Test.new )

    t = nil
    t = Thread.new { server.run } if !do_not_start

    return server, t
end
