require "minitest/autorun"
require "minitest/pride"

require "shrine/storage/flickr"
require "dotenv"

Dotenv.load!

Flickr.configure do |config|
  config.api_key       = ENV.fetch("FLICKR_API_KEY")
  config.shared_secret = ENV.fetch("FLICKR_SHARED_SECRET")
end

class Minitest::Test
  def image
    File.open("test/fixtures/image.jpg")
  end
end
