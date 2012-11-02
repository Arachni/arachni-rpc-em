=begin

    This file is part of the Arachni-RPC EM project and may be subject to
    redistribution and commercial restrictions. Please see the Arachni-RPC EM
    web site for more information on licensing and terms of use.

=end

Gem::Specification.new do |s|
      require File.expand_path( File.dirname( __FILE__ ) ) + '/lib/arachni/rpc/em/version'

      s.name              = "arachni-rpc-em"
      s.version           = Arachni::RPC::EM::VERSION
      s.date              = Time.now.strftime('%Y-%m-%d')
      s.summary           = "The RPC client and server used by the Arachni WebAppSec scanner Grid."
      s.homepage          = "https://github.com/Arachni/arachni-rpc"
      s.email             = "tasos.laskos@gmail.com"
      s.authors           = [ "Tasos Laskos" ]

      s.files             = %w( README.md Rakefile LICENSE.md CHANGELOG.md )
      s.files            += Dir.glob("lib/**/**")
      s.files            += Dir.glob("examples/**/**")
      s.test_files        = Dir.glob("spec/**/**")

      s.extra_rdoc_files  = %w( README.md LICENSE.md CHANGELOG.md )
      s.rdoc_options      = ["--charset=UTF-8"]

      s.add_dependency "eventmachine",  ">= 1.0.0.beta.4"
      s.add_dependency "em-synchrony",  ">= 1.0.0"
      s.add_dependency "arachni-rpc",   "0.1.3"

      s.description = <<description
        EventMachine-based client and server implementation of Arachni-RPC supporting
        TLS encryption, asynchronous and synchronous requests and
        capable of handling remote asynchronous calls that require a block.
description
end
