=begin
                  Arachni-RPC
  Copyright (c) 2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

cwd = File.expand_path( File.dirname( __FILE__ ) )
require File.join( cwd, '../lib/arachni/rpc/', 'em' )

class Parent
    def foo( arg )
        return arg
    end
end

class Bench < Parent

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

server = Arachni::RPC::EM::Server.new(
    :host  => 'localhost',
    :port  => 7332,

    # optional authentication token, if it doesn't match the one
    # set on the client-side the client won't be able to do anything
    # and keep getting exceptions.
    :token => 'superdupersecret',

    # optional serializer (defaults to YAML)
    # see the 'serializer' method at:
    # http://eventmachine.rubyforge.org/EventMachine/Protocols/ObjectProtocol.html#M000369
    :serializer => Marshal,

    # :ssl_ca     => cwd + '/../spec/pems/cacert.pem',
    # :ssl_pkey   => cwd + '/../spec/pems/server/key.pem',
    # :ssl_cert   => cwd + '/../spec/pems/server/cert.pem'
)

#
# This is a way for you to identify methods that pass their result to a block
# instead of simply returning them (which is the most usual operation of async methods.
#
# So no need to change your coding convetions to fit the RPC stuff,
# you can just decide dynamically based on a plethora of data which Ruby provides
# by its 'Method' class.
#
server.add_async_check {
    |method|
    #
    # Must return 'true' for async and 'false' for sync.
    #
    # Very simple check here...
    #
    'async' ==  method.name.to_s.split( '_' )[0]
}

server.add_handler( 'bench', Bench.new )

# this will block forever, call server.shutdown to kill the server.
server.run
