=begin

    This file is part of the Arachni-RPC EM project and may be subject to
    redistribution and commercial restrictions. Please see the Arachni-RPC EM
    web site for more information on licensing and terms of use.

=end

require 'rubygems'
require File.expand_path( File.dirname( __FILE__ ) ) + '/lib/arachni/rpc/em/version'

begin
    require 'rspec'
    require 'rspec/core/rake_task'

    RSpec::Core::RakeTask.new
rescue LoadError => e
    puts 'If you want to run the tests please install rspec first:'
    puts '  gem install rspec'
end

task default: [ :spec ]

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

desc "Cleaning..."
task :clean do
    sh "rm *.gem || true"
end

desc "Build the arachni-rpc-em gem."
task :build => [ :clean ] do
    sh "gem build arachni-rpc-em.gemspec"
end

desc "Build and install the arachni gem."
task :install  => [ :build ] do

    sh "gem install arachni-rpc-em-#{Arachni::RPC::EM::VERSION}.gem"
end

desc "Push a new version to Gemcutter"
task :publish => [ :build ] do

    sh "gem push arachni-rpc-em-#{Arachni::RPC::EM::VERSION}.gem"
end
