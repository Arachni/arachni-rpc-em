=begin
                  Arachni-RPC
  Copyright (c) 2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

$cwd = cwd = File.expand_path( File.dirname( __FILE__ ) )
require File.join( cwd, '../../lib/arachni/rpc/', 'em' )

def rpc_opts
    {
        host:       'localhost',
        port:       7331,
        token:      'superdupersecret',
        serializer: Marshal,
    }
end

def rpc_opts_with_ssl_primitives
    rpc_opts.merge(
        port:     7332,
        ssl_ca:   cwd + '/pems/cacert.pem',
        ssl_pkey: cwd + '/pems/client/key.pem',
        ssl_cert: cwd + '/pems/client/cert.pem'
    )
end

def rpc_opts_with_invalid_ssl_primitives
    rpc_opts_with_ssl_primitives.merge(
        ssl_pkey: cwd + '/pems/client/foo-key.pem',
        ssl_cert: cwd + '/pems/client/foo-cert.pem'
    )
end

def rpc_opts_with_mixed_ssl_primitives
    rpc_opts_with_ssl_primitives.merge(
        ssl_pkey: cwd + '/pems/client/key.pem',
        ssl_cert: cwd + '/pems/client/foo-cert.pem'
    )
end

class Parent
    def foo( arg )
        arg
    end
end

class Test < Parent

    # in order to make inherited methods accessible you've got to explicitly
    # make them public
    private :foo
    public  :foo

    #
    # Uses EventMachine to call the block asynchronously
    #
    def async_foo( arg, &block )
        ::EM.schedule { ::EM.defer { block.call( arg ) if block_given? } }
    end

end

def start_server( opts, do_not_start = false )
    server = Arachni::RPC::EM::Server.new( opts )
    server.add_async_check { |method| method.name.to_s.start_with?( 'async_' ) }
    server.add_handler( 'test', Test.new )
    server.run if !do_not_start
    server
end
