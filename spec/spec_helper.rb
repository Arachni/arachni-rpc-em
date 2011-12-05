
require 'timeout'

def cwd
    File.expand_path( File.dirname( __FILE__ ) )
end

require File.join( cwd, '../lib/arachni/rpc/', 'em' )
require File.join( cwd, 'servers', 'server' )

def rpc_opts
    {
        :host  => 'localhost',
        :port  => 7331,
        :token => 'superdupersecret',
        :serializer => Marshal,
    }
end

def rpc_opts_with_ssl_primitives
    rpc_opts.merge(
        :port       => 7332,
        :ssl_ca     => cwd + '/pems/cacert.pem',
        :ssl_pkey   => cwd + '/pems/client/key.pem',
        :ssl_cert   => cwd + '/pems/client/cert.pem'
    )
end

def rpc_opts_with_invalid_ssl_primitives
    rpc_opts_with_ssl_primitives.merge(
        :ssl_pkey   => cwd + '/pems/client/foo-key.pem',
        :ssl_cert   => cwd + '/pems/client/foo-cert.pem'
    )
end

def rpc_opts_with_mixed_ssl_primitives
    rpc_opts_with_ssl_primitives.merge(
        :ssl_pkey   => cwd + '/pems/client/key.pem',
        :ssl_cert   => cwd + '/pems/client/foo-cert.pem'
    )
end


def start_client( opts )
    Arachni::RPC::EM::Client.new( opts )
end
