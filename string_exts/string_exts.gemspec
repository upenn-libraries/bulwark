$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "string_exts/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "string_exts"
  s.version     = StringExts::VERSION
  s.authors     = ["Katherine Lynch"]
  s.email       = ["katherly@upenn.edu"]
  s.homepage    = "https://github.com/upenn-libraries/colenda/tree/develop/string_exts"
  s.summary     = "Summary of StringExts."
  s.description = "Description of StringExts."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.2.5"

  s.add_development_dependency "sqlite3"
end
