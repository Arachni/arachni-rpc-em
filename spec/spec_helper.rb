
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

def quiet_fork( &block )
    fork {
        $stdout.reopen( '/dev/null', 'w' )
        $stderr.reopen( '/dev/null', 'w' )
        block.call
    }
end

server_pids = []
RSpec.configure do |config|
    config.color = true
    config.add_formatter :documentation

    config.before( :suite ) do
        server_pids << quiet_fork { require File.join( cwd, 'servers', 'basic' ) }
        server_pids << quiet_fork { require File.join( cwd, 'servers', 'with_ssl_primitives' ) }
        server_pids.each { |pid| Process.detach( pid ) }
    end

    config.after( :suite ) do
        server_pids.each { |pid| Process.kill( 'KILL', pid ) }
    end
end
