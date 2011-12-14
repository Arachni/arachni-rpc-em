require File.join( File.expand_path( File.dirname( __FILE__ ) ), '../../../', 'spec_helper' )

describe Arachni::RPC::EM::Client do

    before( :all ) do
        @arg = [
            'one',
            2,
            { :three => 3 },
            [ 4 ]
        ]
    end

    describe "#initialize" do
        it "should be able to properly assign class options (including :role)" do
            opts = rpc_opts.merge( :role => :client )
            start_client( opts ).opts.should == opts
        end
    end

    describe "raw interface" do

        context "when using Threads" do

            it "should be able to perform synchronous calls" do
                @arg.should == start_client( rpc_opts ).call( 'test.foo', @arg )
            end

            it "should be able to perform asynchronous calls" do
                start_client( rpc_opts ).call( 'test.foo', @arg ) {
                    |res|
                    @arg.should == res
                    ::EM.stop
                }
                Arachni::RPC::EM.block!
            end
        end

        context "when run inside the Reactor loop" do

            it "should be able to perform synchronous calls" do
                ::EM.run do

                    ::Arachni::RPC::EM::Synchrony.run do
                        @arg.should == start_client( rpc_opts ).call( 'test.foo', @arg )
                        ::EM.stop
                    end
                end
            end

            it "should be able to perform asynchronous calls" do
                ::EM.run do

                    start_client( rpc_opts ).call( 'test.foo', @arg ) {
                        |res|
                        res.should == @arg
                        ::EM.stop
                    }

                end
            end

        end
    end

    describe "Arachni::RPC::RemoteObjectMapper interface" do
        it "should be able to properly forward synchronous calls" do
            test = Arachni::RPC::RemoteObjectMapper.new( start_client( rpc_opts ), 'test' )
            test.foo( @arg ).should == @arg
            # ::EM.stop
        end

        it "should be able to properly forward synchronous calls" do
            test = Arachni::RPC::RemoteObjectMapper.new( start_client( rpc_opts ), 'test' )
            test.foo( @arg ) {
                |res|
                res.should == @arg
                ::EM.stop
            }
            Arachni::RPC::EM.block!
        end
    end

    describe "exception" do
        context 'when performing asynchronous calls' do

            it "should be returned when requesting inexistent objects" do
                start_client( rpc_opts ).call( 'bar.foo' ) {
                    |res|
                    res.rpc_invalid_object_error?.should be_true
                    ::EM.stop
                }
                Arachni::RPC::EM.block!
            end

            it "should be returned when requesting inexistent or non-public methods" do
                start_client( rpc_opts ).call( 'test.bar' ) {
                    |res|
                    res.rpc_invalid_method_error?.should be_true
                    ::EM.stop
                }
                Arachni::RPC::EM.block!
            end

            it "should be returned when there's a remote exception" do
                start_client( rpc_opts ).call( 'test.foo' ) {
                    |res|
                    res.rpc_remote_exception?.should be_true
                    ::EM.stop
                }
                Arachni::RPC::EM.block!
            end

        end

        context 'when performing synchronous calls' do

            it "should be raised when requesting inexistent objects" do
                begin
                    start_client( rpc_opts ).call( 'bar2.foo' )
                rescue Exception => e
                    e.rpc_invalid_object_error?.should be_true
                end
            end

            it "should be raised when requesting inexistent or non-public methods" do
                begin
                    start_client( rpc_opts ).call( 'test.bar2' )
                rescue Exception => e
                    e.rpc_invalid_method_error?.should be_true
                end

            end

            it "should be raised when there's a remote exception" do
                begin
                    start_client( rpc_opts ).call( 'test.foo' )
                rescue Exception => e
                    e.rpc_remote_exception?.should be_true
                end
            end

        end
    end

    it "should be able to retain stability and consistency under heavy load" do
        client = start_client( rpc_opts )

        n    = 1000
        cnt  = 0

        mismatches = []

        n.times {
            |i|
            client.call( 'test.foo', i ) {
                |res|

                cnt += 1

                mismatches << [i, res] if i != res
                ::EM.stop if cnt == n || !mismatches.empty?
            }
        }

        Arachni::RPC::EM.block!

        mismatches.should be_empty
    end

    it "should throw error when connecting to inexistent server" do
        start_client( rpc_opts.merge( :port => 9999 ) ).call( 'test.foo', @arg ) {
            |res|
            res.rpc_connection_error?.should be_true
            ::EM.stop
        }
        Arachni::RPC::EM.block!
    end

    context "when using valid SSL primitives" do
        it "should be able to establish a connection" do
            res = start_client( rpc_opts_with_ssl_primitives ).call( 'test.foo', @arg )
            res.should == @arg
            ::EM.stop
        end
    end

    context "when using invalid SSL primitives" do
        it "should not be able to establish a connection" do
            start_client( rpc_opts_with_invalid_ssl_primitives ).call( 'test.foo', @arg ){
                |res|
                res.rpc_connection_error?.should be_true
                ::EM.stop
            }
            Arachni::RPC::EM.block!
        end
    end

    context "when using mixed SSL primitives" do
        it "should not be able to establish a connection" do
            start_client( rpc_opts_with_mixed_ssl_primitives ).call( 'test.foo', @arg ){
                |res|
                res.rpc_connection_error?.should be_true
                res.rpc_ssl_error?.should be_true
                ::EM.stop
            }
            Arachni::RPC::EM.block!
        end
    end

end
