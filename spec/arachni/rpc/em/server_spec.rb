require 'spec_helper'

class Arachni::RPC::EM::Server
    public :async?, :async_check, :object_exist?, :public_method?
    attr_accessor :proxy
end

describe Arachni::RPC::EM::Server do

    before( :all ) do
        @opts = rpc_opts.merge( port: 7333 )
        @server = start_server( @opts, true )
    end

    describe '#initialize' do
        it 'should be able to properly setup class options' do
            @server.opts.should == @opts
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

    it 'retains the supplied token' do
        @server.token.should == @opts[:token]
    end

    it 'has a Logger' do
        @server.logger.class.should == ::Logger
    end

    describe '#alive?' do
        subject { @server.alive? }
        it { should == true }
    end

    describe '#async?' do
        context 'when a method is async' do
            it 'returns true' do
                @server.async?( 'test', 'async_foo' ).should be_true
            end
        end

        context 'when a method is sync' do
            it 'returns false' do
                @server.async?( 'test', 'foo' ).should be_false
            end
        end
    end

    describe '#async_check' do
        context 'when a method is async' do
            it 'returns true' do
                @server.async_check( Test.new.method( :async_foo ) ).should be_true
            end
        end

        context 'when a method is sync' do
            it 'returns false' do
                @server.async_check( Test.new.method( :foo ) ).should be_false
            end
        end
    end

    describe '#object_exist?' do
        context 'when an object exists' do
            it 'returns true' do
                @server.object_exist?( 'test' ).should be_true
            end
        end

        context 'when an object does not exist' do
            it 'returns false' do
                @server.object_exist?( 'foo' ).should be_false
            end
        end
    end

    describe '#public_method?' do
        context 'when a method is public' do
            it 'returns true' do
                @server.public_method?( 'test', 'foo' ).should be_true
            end
        end

        context 'when a method is non-existent or not public' do
            it 'returns false' do
                @server.public_method?( 'test', 'bar' ).should be_false
            end
        end
    end

end

