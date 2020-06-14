lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "tapping_device/version"

Gem::Specification.new do |spec|
  spec.name          = "tapping_device"
  spec.version       = TappingDevice::VERSION
  spec.authors       = ["st0012"]
  spec.email         = ["stan001212@gmail.com"]

  spec.summary       = %q{tapping_device lets you understand what your Ruby objects do without digging into the code}
  spec.description   = %q{tapping_device lets you understand what your Ruby objects do without digging into the code} 
  spec.homepage      = "https://github.com/st0012/tapping_device"
  spec.license       = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/st0012/tapping_device"
  spec.metadata["changelog_uri"] = "https://github.com/st0012/tapping_device/releases"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  if ENV["RAILS_VERSION"]
    spec.add_dependency "activerecord", "~> #{ENV["RAILS_VERSION"]}"
  else
    spec.add_dependency "activerecord", ">= 5.2"
  end

  spec.add_dependency "pry" # for using Method#source in MutationTracker
  spec.add_dependency "activesupport"

  spec.add_development_dependency "sqlite3", ">= 1.3.6"
  spec.add_development_dependency "database_cleaner"
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "simplecov", "0.17.1"
end
