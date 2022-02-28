
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "shellopts/version"

Gem::Specification.new do |spec|
  spec.name          = "shellopts"
  spec.version       = ShellOpts::VERSION
  spec.authors       = ["Claus Rasmussen"]
  spec.email         = ["claus.l.rasmussen@gmail.com"]

  spec.summary       = %q{Parse command line options and arguments}
  spec.description   = %q{ShellOpts is a simple command line parsing libray
                          that supports short and long options and subcommands,
                          and has built-in help and error messages}
  spec.homepage      = "http://github.com/clrgit/shellopts"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "forward_to"
  spec.add_dependency "constrain"
  spec.add_dependency "ruby-terminfo"
  spec.add_dependency "indented_io"

  spec.add_development_dependency "bundler", "~> 2.2.10"
  spec.add_development_dependency "rake", ">= 12.3.3"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "simplecov"
end
