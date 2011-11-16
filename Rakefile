=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'rubygems'
require 'rspec'
require 'rspec/core/rake_task'

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

    require File.expand_path( File.dirname( __FILE__ ) ) + '/lib/arachni/rpc/em/version'

    sh "gem install arachni-rpc-em-#{Arachni::RPC::EM::VERSION}.gem"
end


#
# Publishing
#
desc "Push a new version to Gemcutter"
task :publish => [ :build ] do

    require File.expand_path( File.dirname( __FILE__ ) ) + '/lib/arachni/rpc/version'

    sh "gem push arachni-rpc-em-#{Arachni::RPC::EM::VERSION}.gem"
end
