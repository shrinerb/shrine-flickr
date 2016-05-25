require "test_helper"
require "shrine/storage/linter"

describe Shrine::Storage::Flickr do
  def flickr(options = {})
    options[:access_token] ||= [
      ENV.fetch("FLICKR_ACCESS_TOKEN_KEY"),
      ENV.fetch("FLICKR_ACCESS_TOKEN_SECRET"),
    ]
    options[:user] = ENV.fetch("FLICKR_USER")

    Shrine::Storage::Flickr.new(options)
  end

  before do
    @flickr = flickr
    uploader_class = Class.new(Shrine)
    uploader_class.storages[:flickr] = @flickr
    @uploader = uploader_class.new(:flickr)
  end

  after do
    @flickr.clear!
  end

  it "passes the linter" do
    Shrine::Storage::Linter.new(flickr).call(->{image})
  end

  it "passes the linter with album" do
    @flickr.upload(image, id = "foo")
    album = @flickr.flickr.sets.create(title: "foo", primary_photo_id: id.split("-")[2])

    Shrine::Storage::Linter.new(flickr(album: album.id)).call(->{image})
  end

  describe "#upload" do
    it "adds the photo to the album" do
      @flickr.upload(image, id = "foo")
      album = @flickr.flickr.sets.create(title: "foo", primary_photo_id: id.split("-")[2])

      @flickr = flickr(album: album.id)
      @flickr.upload(image, id = "foo")

      assert_equal id.split("-")[2], @flickr.album.photos.find(id.split("-")[2]).id
    end

    it "applies additional upload options" do
      @flickr.upload_options.update(title: "Title")
      @uploader.class.plugin :upload_options, flickr: {description: "Description"}
      uploaded_file = @uploader.upload(image)

      photo = @flickr.flickr.photos.find(uploaded_file.id.split("-")[2])
      photo.get_info!

      assert_equal "Title", photo.title
      assert_equal "Description", photo.description
    end

    it "saves photo attributes to metadata if :store_data is set" do
      @flickr = flickr(store_info: true)
      @flickr.upload(image, id = "foo", shrine_metadata: metadata = {})

      refute_empty metadata.fetch("flickr")
    end
  end

  describe "#update" do
    it "updates the photo metadata" do
      @flickr.upload(image, id = "foo")
      @flickr.update(id, title: "Title", description: "Description")

      photo = @flickr.flickr.photos.find(id.split("-")[2])
      photo.get_info!

      assert_equal "Title", photo.title
      assert_equal "Description", photo.description
    end
  end

  describe "#url" do
    it "returns URL to the image without arguments" do
      @flickr.upload(image, id = "foo")
      assert_match "www.flickr.com", @flickr.url(id)
    end

    it "returns source URL of the image with arguments" do
      @flickr.upload(image, id = "foo")

      assert_match "staticflickr", @flickr.url(id, size: "Square 75")
      assert_match "staticflickr", @flickr.url(id, size: "Original")
    end

    it "raises errors on unavailable or missing sizes" do
      @flickr.upload(image, id = "foo")

      assert_raises(Shrine::Error) { @flickr.url(id, size: "Large 1600") }
      assert_raises(Shrine::Error) { @flickr.url(id, size: "Foo") }
    end
  end
end
