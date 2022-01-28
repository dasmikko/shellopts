
if File.directory?(File.join(File.dirname(File.dirname(File.dirname(__FILE__))), "spec"))
  RUBY_ENV = "development"
else
  RUBY_ENV = "production"
end


