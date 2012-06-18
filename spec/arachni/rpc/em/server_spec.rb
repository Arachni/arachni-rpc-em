require File.join( File.expand_path( File.dirname( __FILE__ ) ), '../../../', 'spec_helper' )

class Arachni::RPC::EM::Server
    public :async?, :async_check, :object_exist?, :public_method?
    attr_accessor :proxy
end

describe Arachni::RPC::EM::Server do

    before( :all ) do
        @opts = rpc_opts.merge( port: 7333 )
        @server = start_server( @opts, true )
    end

    describe "#initialize" do
        it "should be able to properly setup class options" do
            @server.opts.should == @opts
        end
    end

    it "should retain the supplied token" do
        @server.token.should == @opts[:token]
    end

    it "should have a Logger" do
        @server.logger.class.should == ::Logger
    end

    describe "#alive?" do
        subject { @server.alive? }
        it { should == true }
    end

    describe "#async?" do

        it "should return true for async methods" do
            @server.async?( 'test', 'async_foo' ).should be_true
        end

        it "should return false for sync methods" do
            @server.async?( 'test', 'foo' ).should be_false
        end
    end

    describe "#async_check" do

        it "should return true for async methods" do
            @server.async_check( Test.new.method( :async_foo ) ).should be_true
        end

        it "should return false for sync methods" do
            @server.async_check( Test.new.method( :foo ) ).should be_false
        end
    end

    describe "#object_exist?" do

        it "should return true for valid objects" do
            @server.object_exist?( 'test' ).should be_true
        end

        it "should return false for inexistent objects" do
            @server.object_exist?( 'foo' ).should be_false
        end
    end

    describe "#public_method?" do

        it "should return true for public methods" do
            @server.public_method?( 'test', 'foo' ).should be_true
        end

        it "should return false for inexistent or non-public methods" do
            @server.public_method?( 'test', 'bar' ).should be_false
        end
    end

end

