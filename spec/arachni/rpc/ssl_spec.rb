require File.join( File.expand_path( File.dirname( __FILE__ ) ), '../../', 'spec_helper' )

class SSL
    include Arachni::RPC::EM::SSL

    def initialize( opts )
        @opts = opts
    end
end

describe Arachni::RPC::EM::SSL do

    before( :all ) do
        @ssl = SSL.new( rpc_opts_with_ssl_primitives )
    end

    describe "#ca_store" do
        it "should return an OpenSSL::X509::Store" do
            @ssl.ca_store.class.should == OpenSSL::X509::Store
        end
    end

    describe "#ssl_verify_peer" do
        it "should return true on valid peer cert" do
            cert = rpc_opts_with_ssl_primitives[:ssl_cert]
            @ssl.ssl_verify_peer( File.read( cert ) ).should be_true
        end

        it "should return false on invalid peer cert" do
            cert = rpc_opts_with_invalid_ssl_primitives[:ssl_cert]
            @ssl.ssl_verify_peer( File.read( cert ) ).should be_false
        end
    end

    describe "#are_we_a_client?" do

        context "when run from inside a client" do
            it "should return true" do
                opts = rpc_opts_with_ssl_primitives.merge( :role => :client )
                SSL.new( opts ).are_we_a_client?.should be_true
            end
        end

        context "when run from inside a server" do
            it "should return false" do
                opts = rpc_opts_with_ssl_primitives.merge( :role => :server )
                SSL.new( opts ).are_we_a_client?.should be_false
            end
        end

    end

    describe "#ssl_opts?" do
        context "when all SSL opts have been provided" do
            it "should return true" do
                @ssl.ssl_opts?.should be_true
            end
        end

        context "when not all SSL opts have been provided" do
            it "should return false" do
                opts = rpc_opts_with_ssl_primitives.merge( :ca_cert => nil )
                SSL.new( opts ).are_we_a_client?.should be_false
            end
        end
    end

end
