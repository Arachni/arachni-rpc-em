=begin
                  Arachni-RPC
  Copyright (c) 2011 Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

# require 'arachni/rpc'
require File.join( File.expand_path( File.dirname( __FILE__ ) ), '../lib/arachni/rpc/', 'em' )

#
# You don't *need* to stick the whole thing inside an ::EM.run block,
# the system will manage EM on its own...however you *can* if you want to
# or if you're working inside a framework that already runs EventMachine.
::EM.run do

    # connect to the server
    client = Arachni::RPC::EM::Client.new(
        host:       'localhost',
        port:       7332,

        # optional authentication token, if it doesn't match the one
        # set on the server-side you'll be getting exceptions.
        token:      'superdupersecret',

        # optional serializer (defaults to YAML)
        # see the 'serializer' method at:
        # http://eventmachine.rubyforge.org/EventMachine/Protocols/ObjectProtocol.html#M000369
        serializer: Marshal
    )

    bench = Arachni::RPC::RemoteObjectMapper.new( client, 'bench' )

    #
    # There's one downside though, if you want to run this thing inside an
    # ::EM.run block: you'll have to wrap all sync calls in a ::Arachni::RPC::EM::EM::Synchrony.run block.
    #
    # Like so:
    ::Arachni::RPC::EM::Synchrony.run do
        p bench.foo( 'First sync call in individual Synchrony block.' )
        # => "First sync call in individual Synchrony block."
    end

    # you can use it again individually
    ::Arachni::RPC::EM::Synchrony.run do
        p bench.foo( 'Second sync call in individual Synchrony block.' )
        # => "Second sync call in individual Synchrony block."
    end

    # or just wrap lots of calls in it
    ::Arachni::RPC::EM::Synchrony.run do
        p bench.foo( 'Third sync call in individual Synchrony block.' )
        # => "Third sync call in individual Synchrony block."

        p bench.foo( '--> And this one is in the same block as well.' )
        # => "--> And this one is in the same block as well."

        p bench.async_foo( 'This is a sync call to an async remote method.' )
        # => "This is a sync call to an async remote method."
    end

    # async calls are the same
    bench.foo( 'This is an async call... business as usual. :)' ) do |res|
        p res
        # => "This is an async call... business as usual. :)"
    end

    bench.async_foo( 'This is an async call to an async remote method.' ) do |res|
        p res
        # => "This is an async call to an async remote method."
    end

end
