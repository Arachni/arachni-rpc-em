=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

Gem::Specification.new do |s|
      require File.expand_path( File.dirname( __FILE__ ) ) + '/lib/arachni/rpc/em/version'

      s.name              = "arachni-rpc-em"
      s.version           = Arachni::RPC::EM::VERSION
      s.date              = Time.now.strftime('%Y-%m-%d')
      s.summary           = "The RPC client and server used by the Arachni WebAppSec scanner."
      s.homepage          = "https://github.com/Arachni/arachni-rpc"
      s.email             = "tasos.laskos@gmail.com"
      s.authors           = [ "Tasos Laskos" ]

      s.files             = %w( README.md Rakefile LICENSE.md CHANGELOG.md )
      s.files            += Dir.glob("lib/**/**")
      s.files            += Dir.glob("examples/**/**")
      s.test_files        = Dir.glob("examples/**/**")
      s.test_files       += Dir.glob("spec/**/**")

      s.extra_rdoc_files  = %w( README.md LICENSE.md CHANGELOG.md )
      s.rdoc_options      = ["--charset=UTF-8"]

      s.add_dependency "eventmachine",  "~> 1.0.0.beta.4"
      s.add_dependency "em-synchrony",  "~> 1.0.0"

      s.description = <<description
        EventMachine based RPC client and server capable of a few thousands requests per second (depending on call size, network conditions and the like).
        It supports TLS encryption, asynchronous and synchronous requests and is capable of handling remote asynchronous calls that require a block.
description
end
