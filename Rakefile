=begin

    This file is part of the Arachni-RPC EM project and may be subject to
    redistribution and commercial restrictions. Please see the Arachni-RPC EM
    web site for more information on licensing and terms of use.

=end

require 'rubygems'
require 'rspec'
require 'rspec/core/rake_task'

require File.expand_path( File.dirname( __FILE__ ) ) + '/lib/arachni/rpc/em/version'

RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = ['--options', "\"#{File.dirname(__FILE__)}/spec/spec.opts\""]
end

desc "Generate docs"

task :docs do

    outdir = "../arachni-rpc-pages"
    sh "mkdir #{outdir}" if !File.directory?( outdir )

    sh "yardoc --verbose --title \
      \"Arachni-RPC\" \
       lib/* -o #{outdir} \
      - CHANGELOG.md LICENSE.md"


    sh "rm -rf .yard*"
end


#
# Cleans reports and logs
#
desc "Cleaning..."
task :clean do
    sh "rm *.gem || true"
end



#
# Building
#
desc "Build the arachni-rpc-em gem."
task :build => [ :clean ] do
    sh "gem build arachni-rpc-em.gemspec"
end


#
# Installing
#
desc "Build and install the arachni gem."
task :install  => [ :build ] do

    sh "gem install arachni-rpc-em-#{Arachni::RPC::EM::VERSION}.gem"
end


#
# Publishing
#
desc "Push a new version to Gemcutter"
task :publish => [ :build ] do

    sh "gem push arachni-rpc-em-#{Arachni::RPC::EM::VERSION}.gem"
end
