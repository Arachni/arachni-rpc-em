require 'rspec'
require 'timeout'

require_relative '../lib/arachni/rpc/em'
require_relative 'servers/server'

def start_client( opts )
    Arachni::RPC::EM::Client.new( opts )
end

def quiet_fork( &block )
    fork {
        #$stdout.reopen( '/dev/null', 'w' )
        #$stderr.reopen( '/dev/null', 'w' )
        block.call
    }
end

def quiet_spawn( file )
    Process.spawn 'ruby ' + file
end

server_pids = []
RSpec.configure do |config|
    config.color = true
    config.add_formatter :documentation

    config.before( :suite ) do
        cwd = File.expand_path( File.dirname( __FILE__ ) )
        server_pids << quiet_spawn( File.join( cwd, 'servers', 'basic.rb' ) )
        server_pids << quiet_spawn( File.join( cwd, 'servers', 'with_ssl_primitives.rb' ) )
        server_pids << quiet_spawn( File.join( cwd, 'servers', 'with_fallback.rb' ) )
        server_pids << quiet_spawn( File.join( cwd, 'servers', 'unix_socket.rb' ) )
        server_pids.each { |pid| Process.detach( pid ) }
        sleep 2
    end

    config.after( :suite ) do
        server_pids.each { |pid| Process.kill( 'KILL', pid ) }
    end
end
