
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
                          that covers most modern use cases incl. sub-commands.
                          Options and commands are specified using a
                          getopt(1)-like string that is interpreted by the
                          library to process the command line}
  spec.homepage      = "http://github.com/clrgit/shellopts"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "forward_to"
  spec.add_dependency "constrain"

  spec.add_development_dependency "bundler", "~> 2.2.10"
  spec.add_development_dependency "rake", ">= 12.3.3"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "indented_io"
  spec.add_development_dependency "simplecov"

  # In development mode override load paths for gems whose source are located
  # as siblings of this project directory. Only for fox-project. TODO Remove
# if File.directory?("#{__dir__}/.git")
#   local_projects = Dir["../*"].select { |path| 
#     File.directory?(path) && File.exist?("#{path}/Gemfile")
#   }.map { |relpath| "#{File.absolute_path(relpath)}/lib" }
#   $LOAD_PATH.unshift *local_projects
# end
end
