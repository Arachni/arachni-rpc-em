=begin
                  Arachni-RPC
  Copyright (c) 2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

cwd = File.expand_path( File.dirname( __FILE__ ) )
require File.join( cwd, '../lib/arachni/rpc/', 'em' )


# connect to the server
client = Arachni::RPC::EM::Client.new(
    :host  => 'localhost',
    :port  => 7332,

    # optional authentication token, if it doesn't match the one
    # set on the server-side you'll be getting exceptions.
    :token => 'superdupersecret',

    # optional serializer (defaults to YAML)
    # see the 'serializer' method at:
    # http://eventmachine.rubyforge.org/EventMachine/Protocols/ObjectProtocol.html#M000369
    :serializer => Marshal,

    #
    # Connection keep alive is set to true by default, this means that
    # a single connection will be maintained and all calls will pass
    # through it.
    # This bypasses a bug in EventMachine and allows you to perform thousands
    # of calls without issue.
    #
    # However, you are responsible for closing the connection when you're done.
    #
    # If keep alive is set to false then each call will go through its own connection
    # and the responsibility for closing that connection falls on Arachni-RPC.
    #
    # Unfortunately, if you try to make a greater number of calls than your system's
    # maximum open file descriptors limit EventMachine will freak-out.
    #
    :keep_alive => false,

    #
    # In order to enable peer verification one must first provide
    # the following:
    #
    # SSL CA certificate
    # :ssl_ca     => cwd + '/../spec/pems/cacert.pem',
    # SSL private key
    # :ssl_pkey   => cwd + '/../spec/pems/client/key.pem',
    # SSL certificate
    # :ssl_cert   => cwd + '/../spec/pems/client/cert.pem'
)

# Make things easy on the eyes using the mapper, it allows you to do this:
#
#    res = bench.foo( arg )
#
# Instead of:
#
#    res = client.call( 'bench.foo', arg )
#
bench = Arachni::RPC::RemoteObjectMapper.new( client, 'bench' )

#
# In order to perform an asynchronous call you will need to provide a block,
# even if it is an empty one.
#
bench.foo( 'This is an async call to "bench.foo".' ) {
    |res|

    p res
    # => "This is an async call to \"bench.foo\"."

    # did something RPC related go wrong?
    # p res.rpc_exception?
    # => false

    # did something go wrong on the server-side?
    # p res.rpc_remote_exception?
    # => false

    # did the connection die abruptly?
    # p res.rpc_connection_error?
    # => false

    # did we call an object for which there is no handler on the server-side?
    # p res.rpc_invalid_object_error?
    # => false

    # did we call a server-side method that isn't existent or public?
    # p res.rpc_invalid_method_error?
    # => false

    # was there an authentication token mismatch?
    # p res.rpc_invalid_token_error?
    # => false
}



#
# On the server-side this is an async method but works just like everything else here.
#
# You'll need to kind-of specify the async methods on the server-side,
# check the server example file for more info.
#
bench.async_foo( 'This is an async call to "bench.async_foo".' ) {
    |res|
    p res
    # => "This is an async call to \"bench.async_foo\"."
}

p bench.async_foo( 'This is a sync call to "bench.async_foo".' )
# => "This is a sync call to \"bench.async_foo\"."


#
# To perform a sync (blocking) call do the usual stuff.
#
# This is thread safe so if you'd rather use Threads instead of async calls
# for that extra performance kick you go ahead and do your thing now...
#
p bench.foo( 'This is a sync call to "bench.foo".' )
# => "This is a sync call to \"bench.foo\"."


#
# When you are performing a synchronous call and things go wrong
# an exception will be thrown.
#
# Exceptions on the server-side unrelated to the RPC system will be forwarded.
#

#
# Non-existent object.
#
blah = Arachni::RPC::RemoteObjectMapper.new( client, 'blah' )
begin
    p blah.something
rescue Exception => e
    p e  # => #<Arachni::RPC::EM::Exceptions::InvalidObject: Trying to access non-existent object 'blah'.>
end

#
# Non-existent or non-public method.
#
begin
    p bench.fdoo
rescue Exception => e
    p e # => #<Arachni::RPC::EM::Exceptions::InvalidMethod: Trying to access non-public method 'fdoo'.>
end

#
# When you are performing an asynchronous call and things go wrong
# an exception will be returned.
#
# It will *NOT* be thrown!
# It will be *RETURNED*!
#
blah.something {
    |res|
    p res # => #<Arachni::RPC::EM::Exceptions::InvalidObject: Trying to access non-existent object 'blah'.>

    # RPC Exception helper methods have been added to all Ruby objects (except BasicObject)
    # so they'll always be there when you need them.

    # p res.rpc_exception? # => true
    # p res.rpc_invalid_object_error? # => true
}

#
# We don't know when async calls will return so we wait forever.
#
# Call ::EM.stop to break-out.
#
Arachni::RPC::EM.block!

