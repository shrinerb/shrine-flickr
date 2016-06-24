require "bundler/setup"

require "minitest/autorun"
require "minitest/pride"

require "shrine/storage/flickr"
require "dotenv"

require "forwardable"
require "stringio"

Dotenv.load!

Flickr.configure do |config|
  config.api_key       = ENV.fetch("FLICKR_API_KEY")
  config.shared_secret = ENV.fetch("FLICKR_SHARED_SECRET")
end

class FakeIO
  def initialize(content)
    @io = StringIO.new(content)
  end

  extend Forwardable
  delegate Shrine::IO_METHODS.keys => :@io
end

class Minitest::Test
  def image
    FakeIO.new(File.read("test/fixtures/image.jpg"))
  end
end
