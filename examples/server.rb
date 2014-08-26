=begin
                  Arachni-RPC
  Copyright (c) 2011 Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

cwd = File.expand_path( File.dirname( __FILE__ ) )
require File.join( cwd, '../lib/arachni/rpc/', 'em' )

class Parent
    def foo( arg )
        arg
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
    host:       'localhost',
    port:       7332,

    # optional authentication token, if it doesn't match the one
    # set on the client-side the client won't be able to do anything
    # and keep getting exceptions.
    token:      'superdupersecret',

    # optional serializer (defaults to YAML)
    # see the 'serializer' method at:
    # http://eventmachine.rubyforge.org/EventMachine/Protocols/ObjectProtocol.html#M000369
    #
    # Use Marshal for performance as the primary serializer.
    serializer: Marshal,

    # Fallback to YAML for interoperability -- used for requests that can't be parsed by Marshal.load.
    fallback_serializer: YAML,

    # ssl_ca:   cwd + '/../spec/pems/cacert.pem',
    # ssl_pkey: cwd + '/../spec/pems/server/key.pem',
    # ssl_cert: cwd + '/../spec/pems/server/cert.pem'
)

#
# This is a way for you to identify methods that pass their result to a block
# instead of simply returning them (which is the most usual operation of async methods.
#
# So no need to change your coding convetions to fit the RPC stuff,
# you can just decide dynamically based on a plethora of data which Ruby provides
# by its 'Method' class.
#
server.add_async_check do |method|
    #
    # Must return 'true' for async and 'false' for sync.
    #
    # Very simple check here...
    #
    method.name.to_s.start_with? 'async_'
end

server.add_handler( 'bench', Bench.new )

# this will block forever, call server.shutdown to kill the server.
server.run
