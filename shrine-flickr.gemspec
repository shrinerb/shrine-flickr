Gem::Specification.new do |gem|
  gem.name          = "shrine-flickr"
  gem.version       = "1.0.0"

  gem.required_ruby_version = ">= 2.1"

  gem.summary      = "Provides Flickr storage for Shrine."
  gem.homepage     = "https://github.com/janko-m/shrine-flickr"
  gem.authors      = ["Janko Marohnić"]
  gem.email        = ["janko.marohnic@gmail.com"]
  gem.license      = "MIT"

  gem.files        = Dir["README.md", "LICENSE.txt", "lib/**/*.rb", "shrine-flickr.gemspec"]
  gem.require_path = "lib"

  gem.add_dependency "flickr-objects", ">= 0.6.1"
  gem.add_dependency "down", ">= 1.0.3"

  gem.add_development_dependency "rake"
  gem.add_development_dependency "shrine"
  gem.add_development_dependency "minitest"
  gem.add_development_dependency "dotenv"
end
