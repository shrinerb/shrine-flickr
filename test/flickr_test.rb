require "test_helper"
require "shrine/storage/flickr"

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
    @flickr.clear!(:confirm)
  end

  describe "#upload" do
    it "uploads and updates the location and metadata" do
      @flickr.upload(image, id = "foo", metadata = {})

      assert_match /^\d+$/, id
      refute_empty metadata["flickr_sizes"]
    end

    it "adds the photo to the album" do
      @flickr.upload(image, id = "foo")
      album = @flickr.flickr.sets.create(title: "foo", primary_photo_id: id)

      @flickr = flickr(album: album.id)
      @flickr.upload(image, id = "foo")

      assert_equal id, @flickr.album.photos.find(id).id
    end

    it "applies additional upload options" do
      @flickr.upload_options.update(title: "Title")
      @flickr.upload(image, id = "foo", {"flickr" => {description: "Description"}})

      photo = @flickr.flickr.photos.find(id)
      photo.get_info!

      assert_equal "Title", photo.title
      assert_equal "Description", photo.description
    end
  end

  describe "#download" do
    it "downloads the photo from original url" do
      uploaded_file = @uploader.upload(image)

      assert_equal uploaded_file.download.size, image.size
    end
  end

  describe "#open" do
    it "is implemented in terms of #download" do
      uploaded_file = @uploader.upload(image)

      assert_equal image.size, uploaded_file.read.size
    end
  end

  describe "#exists?" do
    it "returns true for photo that exists" do
      @flickr.upload(image, id = "foo")

      assert @flickr.exists?(id)
    end

    it "returns false for photo that doesn't exist" do
      refute @flickr.exists?("foo")
    end
  end

  describe "#delete" do
    it "deletes the photo" do
      @flickr.upload(image, id = "foo")
      @flickr.delete(id)

      refute @flickr.exists?(id)
    end
  end

  describe "#url" do
    it "behaves correctly" do
      uploaded_file = @uploader.upload(image)

      assert_includes uploaded_file.url(size: :square_75), "_s.jpg"
      assert_includes uploaded_file.url(size: "Thumbnail"), "_t.jpg"
      assert_includes uploaded_file.url, "_o.jpg"
    end
  end
end
