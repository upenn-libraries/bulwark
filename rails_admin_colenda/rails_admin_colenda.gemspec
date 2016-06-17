$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "rails_admin_colenda/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rails_admin_colenda"
  s.version     = RailsAdminColenda::VERSION
  s.authors     = ["Katherine Lynch"]
  s.email       = ["katherly@upenn.edu"]
  s.homepage    = "https://github.com/upenn-libraries/colenda"
  s.summary     = "Theme for supporting digitization workflows in Colenda."
  s.description = "Supports multi-step digitization practices in Colenda."
  s.license     = "MIT"

  s.files = Dir["{lib,vendor}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "~> 4.2.5"
end
