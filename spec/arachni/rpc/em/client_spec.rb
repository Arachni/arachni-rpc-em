require 'spec_helper'

describe Arachni::RPC::EM::Client do

    before( :all ) do
        @arg = [ 'one', 2,
            { :three => 3 }, [ 4 ]
        ]
    end

    it 'retains stability and consistency under heavy load' do
        client = start_client( rpc_opts )

        n   = 100_000
        cnt = 0

        mismatches = []

        n.times do |i|
            arg = 'a' * i
            client.call( 'test.foo', arg ) do |res|
                cnt += 1
                mismatches << [i, arg, res] if arg != res
                ::EM.stop if cnt == n || mismatches.any?
            end
        end

        Arachni::RPC::EM.block
        cnt.should > 0
        mismatches.should be_empty
    end

    describe '#initialize' do
        it 'should be able to properly assign class options (including :role)' do
            opts = rpc_opts.merge( role: :client )
            start_client( opts ).opts.should == opts
        end

        context 'when passed no connection information' do
            it 'raises ArgumentError' do
                begin
                    described_class.new({})
                rescue => e
                    e.should be_kind_of ArgumentError
                end
            end
        end

        describe 'option' do
            describe :socket do
                it 'connects to it' do
                    client = start_client( rpc_opts_with_socket )
                    client.call( 'test.foo', 1 ).should == 1
                end

                it 'retains stability and consistency under heavy load' do
                    client = start_client( rpc_opts_with_socket )

                    n    = 100_000
                    cnt  = 0

                    mismatches = []

                    n.times do |i|
                        arg = 'a' * i
                        client.call( 'test.foo', arg ) do |res|
                            cnt += 1
                            mismatches << [i, arg, res] if arg != res
                            ::EM.stop if cnt == n || mismatches.any?
                        end
                    end

                    Arachni::RPC::EM.block
                    cnt.should > 0
                    mismatches.should be_empty
                end

                context 'when passed an invalid socket path' do
                    it 'raises ArgumentError' do
                        begin
                            described_class.new( socket: 'blah' )
                        rescue => e
                            e.should be_kind_of ArgumentError
                        end
                    end
                end
            end
        end

        context 'when passed a host but not a port' do
            it 'raises ArgumentError' do
                begin
                    described_class.new( host: 'test' )
                rescue => e
                    e.should be_kind_of ArgumentError
                end
            end
        end

        context 'when passed a port but not a host' do
            it 'raises ArgumentError' do
                begin
                    described_class.new( port: 9999 )
                rescue => e
                    e.should be_kind_of ArgumentError
                end
            end
        end

        context 'when passed an invalid port' do
            it 'raises ArgumentError' do
                begin
                    described_class.new( host: 'tt', port: 'blah' )
                rescue => e
                    e.should be_kind_of ArgumentError
                end
            end
        end
    end

    context 'when using a fallback serializer' do
        context 'and the primary serializer fails' do
            it 'should use the fallback' do
                opts = rpc_opts.merge( port: 7333, serializer: YAML )
                start_client( opts ).call( 'test.foo', @arg ).should == @arg

                opts = rpc_opts.merge( port: 7333, serializer: Marshal )
                start_client( opts ).call( 'test.foo', @arg ).should == @arg
            end
        end
    end

    describe 'raw interface' do
        context 'when using Threads' do
            it 'should be able to perform synchronous calls' do
                @arg.should == start_client( rpc_opts ).call( 'test.foo', @arg )
            end

            it 'should be able to perform asynchronous calls' do
                start_client( rpc_opts ).call( 'test.foo', @arg ) do |res|
                    @arg.should == res
                    ::EM.stop
                end
                Arachni::RPC::EM.block
            end
        end

        context 'when run inside the Reactor loop' do
            it 'should be able to perform synchronous calls' do
                ::EM.run {
                    ::Arachni::RPC::EM::Synchrony.run do
                        @arg.should == start_client( rpc_opts ).call( 'test.foo', @arg )
                        ::EM.stop
                    end
                }
            end

            it 'should be able to perform asynchronous calls' do
                ::EM.run {
                    start_client( rpc_opts ).call( 'test.foo', @arg ) do |res|
                        res.should == @arg
                        ::EM.stop
                    end
                }
            end

        end
    end

    describe 'Arachni::RPC::RemoteObjectMapper interface' do
        it 'should be able to properly forward synchronous calls' do
            test = Arachni::RPC::RemoteObjectMapper.new( start_client( rpc_opts ), 'test' )
            test.foo( @arg ).should == @arg
        end

        it 'should be able to properly forward synchronous calls' do
            test = Arachni::RPC::RemoteObjectMapper.new( start_client( rpc_opts ), 'test' )
            test.foo( @arg ) do |res|
                res.should == @arg
                ::EM.stop
            end
            Arachni::RPC::EM.block
        end
    end

    context 'when performing an asynchronous call' do
        context 'and connecting to a non-existent server' do
            it 'returns Arachni::RPC::Exceptions::ConnectionError' do
                options = rpc_opts.merge( host: 'dddd', port: 999339 )
                start_client( options ).call( 'test.foo', @arg ) do |res|
                    res.rpc_connection_error?.should be_true
                    res.should be_kind_of Arachni::RPC::Exceptions::ConnectionError
                    ::EM.stop
                end
                Arachni::RPC::EM.block
            end
        end

        context 'and requesting a non-existent object' do
            it 'returns Arachni::RPC::Exceptions::InvalidObject' do
                start_client( rpc_opts ).call( 'bar.foo' ) do |res|
                    res.rpc_invalid_object_error?.should be_true
                    res.should be_kind_of Arachni::RPC::Exceptions::InvalidObject
                    ::EM.stop
                end
                Arachni::RPC::EM.block
            end
        end

        context 'and requesting a non-public method' do
            it 'returns Arachni::RPC::Exceptions::InvalidMethod' do
                start_client( rpc_opts ).call( 'test.bar' ) do |res|
                    res.rpc_invalid_method_error?.should be_true
                    res.should be_kind_of Arachni::RPC::Exceptions::InvalidMethod
                    ::EM.stop
                end
                Arachni::RPC::EM.block
            end
        end

        context 'and there is a remote exception' do
            it 'returns Arachni::RPC::Exceptions::RemoteException' do
                start_client( rpc_opts ).call( 'test.foo' ) do |res|
                    res.rpc_remote_exception?.should be_true
                    res.should be_kind_of Arachni::RPC::Exceptions::RemoteException
                    ::EM.stop
                end
                Arachni::RPC::EM.block
            end
        end
    end

    context 'when performing a synchronous call' do
        #context 'and connecting to a non-existent server' do
        #    it 'raises Arachni::RPC::Exceptions::ConnectionError' do
        #        begin
        #            options = rpc_opts.merge( host: 'dddd', port: 999339 )
        #            start_client( options ).call( 'test.foo', @arg )
        #        rescue => e
        #            e.rpc_connection_error?.should be_true
        #            e.should be_kind_of Arachni::RPC::Exceptions::ConnectionError
        #        end
        #    end
        #end

        context 'and requesting a non-existent object' do
            it 'raises Arachni::RPC::Exceptions::InvalidObject' do
                begin
                    start_client( rpc_opts ).call( 'bar2.foo' )
                rescue Exception => e
                    e.rpc_invalid_object_error?.should be_true
                    e.should be_kind_of Arachni::RPC::Exceptions::InvalidObject
                end
            end
        end

        context 'and requesting a non-public method' do
            it 'raises Arachni::RPC::Exceptions::InvalidMethod' do
                begin
                    start_client( rpc_opts ).call( 'test.bar2' )
                rescue Exception => e
                    e.rpc_invalid_method_error?.should be_true
                    e.should be_kind_of Arachni::RPC::Exceptions::InvalidMethod
                end
            end
        end

        context 'and there is a remote exception' do
            it 'raises Arachni::RPC::Exceptions::RemoteException' do
                begin
                    start_client( rpc_opts ).call( 'test.foo' )
                rescue Exception => e
                    e.rpc_remote_exception?.should be_true
                    e.should be_kind_of Arachni::RPC::Exceptions::RemoteException
                end
            end
        end
    end

    context 'when using valid SSL primitives' do
        it 'should be able to establish a connection' do
            res = start_client( rpc_opts_with_ssl_primitives ).call( 'test.foo', @arg )
            res.should == @arg
            ::EM.stop
        end
    end

    context 'when using invalid SSL primitives' do
        it 'should not be able to establish a connection' do
            start_client( rpc_opts_with_invalid_ssl_primitives ).call( 'test.foo', @arg ) do |res|
                res.rpc_connection_error?.should be_true
                ::EM.stop
            end
            Arachni::RPC::EM.block
        end
    end

    context 'when using mixed SSL primitives' do
        it 'should not be able to establish a connection' do
            start_client( rpc_opts_with_mixed_ssl_primitives ).call( 'test.foo', @arg ) do |res|
                res.rpc_connection_error?.should be_true
                res.rpc_ssl_error?.should be_true
                ::EM.stop
            end
            Arachni::RPC::EM.block
        end
    end

end
