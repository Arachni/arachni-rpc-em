=begin

    This file is part of the Arachni-RPC EM project and may be subject to
    redistribution and commercial restrictions. Please see the Arachni-RPC EM
    web site for more information on licensing and terms of use.

=end

require 'rubygems'
require 'bundler'
require_relative 'lib/arachni/rpc/em/version'

Bundler::GemHelper.install_tasks

begin
    require 'rspec'
    require 'rspec/core/rake_task'

    RSpec::Core::RakeTask.new
rescue LoadError => e
    puts 'If you want to run the tests please install rspec first:'
    puts '  gem install rspec'
end

task default: [ :build, :spec ]

desc 'Generate docs'
task :docs do
    outdir = '../arachni-rpc-em-docs'

    sh "mkdir #{outdir}" if !File.directory?( outdir )
    sh "yardoc -o #{outdir}"
    sh 'rm -rf .yardoc'
end

desc 'Push a new version to RubyGems'
task :publish => [ :release ]

desc 'Build Arachni and run all the tests.'
task :default => [ :build, :spec ]
