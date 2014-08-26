=begin
                  Arachni-RPC
  Copyright (c) 2011 Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require_relative '../../lib/arachni/rpc/em'

def pems_path
    File.expand_path( File.dirname( __FILE__ ) + '/../' )
end

def rpc_opts
    {
        host:       'localhost',
        port:       7331,
        token:      'superdupersecret',
        serializer: Marshal,
    }
end

def rpc_opts_with_socket
    opts = rpc_opts
    opts.delete( :host )
    opts.delete( :port )

    opts.merge( socket: '/tmp/arachni-rpc-em-test' )
end

def rpc_opts_with_ssl_primitives
    rpc_opts.merge(
        port:     7332,
        ssl_ca:   pems_path + '/pems/cacert.pem',
        ssl_pkey: pems_path + '/pems/client/key.pem',
        ssl_cert: pems_path + '/pems/client/cert.pem'
    )
end

def rpc_opts_with_invalid_ssl_primitives
    rpc_opts_with_ssl_primitives.merge(
        ssl_pkey: pems_path + '/pems/client/foo-key.pem',
        ssl_cert: pems_path + '/pems/client/foo-cert.pem'
    )
end

def rpc_opts_with_mixed_ssl_primitives
    rpc_opts_with_ssl_primitives.merge(
        ssl_pkey: pems_path + '/pems/client/key.pem',
        ssl_cert: pems_path + '/pems/client/foo-cert.pem'
    )
end

class Parent
    def foo( arg )
        arg
    end
end

class Test < Parent

    # In order to make inherited methods accessible you've got to explicitly
    # make them public.
    private :foo
    public  :foo

    # Uses EventMachine to call the block asynchronously
    def async_foo( arg, &block )
        ::EM.schedule { block.call( arg ) if block_given? }
    end

end

def start_server( opts, do_not_start = false )
    server = Arachni::RPC::EM::Server.new( opts )
    server.add_async_check { |method| method.name.to_s.start_with?( 'async_' ) }
    server.add_handler( 'test', Test.new )
    server.run if !do_not_start
    server
end
