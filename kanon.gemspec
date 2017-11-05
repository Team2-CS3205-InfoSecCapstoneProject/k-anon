# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "kanon/version"

Gem::Specification.new do |spec|
  spec.name          = "kanon"
  spec.version       = Kanon::VERSION
  spec.authors       = ["CS3205 Team 2"]
  spec.email         = ["cs3205-team2@u.nus.edu"]

  spec.summary       = %q{K-Anonymity Project}
  spec.homepage      = "https://github.com/mustaqiimuhar/team2-k-anon"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "dogstatsd-ruby"
  spec.add_dependency "rack-protection"
  spec.add_dependency "rest-client"
  spec.add_dependency "rotp"
  spec.add_dependency "rqrcode"
  spec.add_dependency "sanitize"
  spec.add_dependency "sentry-raven"
  spec.add_dependency "sequel"
  spec.add_dependency "sequel_secure_password"
  spec.add_dependency "sinatra"
  spec.add_dependency "sinatra-flash"
  spec.add_dependency "sqlite3"
  spec.add_dependency "sysrandom"
  spec.add_dependency "thin"
  spec.add_dependency "warden"

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
