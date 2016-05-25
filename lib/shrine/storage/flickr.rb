require "shrine"
require "flickr-objects"
require "down"
require "net/http"
require "uri"

class Shrine
  module Storage
    class Flickr
      attr_reader :person, :flickr, :upload_options, :album

      def initialize(user:, access_token:, album: nil, upload_options: {}, store_info: nil)
        @flickr = ::Flickr.new(*access_token)
        @person = @flickr.people.find(user)
        @upload_options = upload_options
        @store_info = store_info
        @album = @flickr.sets.find(album) if album
      end

      def upload(io, id, shrine_metadata: {}, **upload_options)
        options = {title: shrine_metadata["filename"]}
        options.update(@upload_options)
        options.update(upload_options)

        photo_id = flickr.upload(io, options)
        album.add_photo(photo_id) if album

        photo = photo(photo_id).get_info!
        update_id!(photo, id)
        update_metadata!(photo, shrine_metadata)

        photo.attributes
      end

      def download(id)
        Down.download(url(id, size: "Original"))
      end

      def update(id, options = {})
        photo(photo_id(id)).set_meta(options)
      end

      def open(id)
        download(id)
      end

      def read(id)
        Net::HTTP.get(URI.parse(url(id, size: "Original")))
      end

      def exists?(id)
        !!photo(photo_id(id)).get_info!
      rescue ::Flickr::ApiError => error
        raise error if error.code != 1
        false
      end

      def delete(id)
        photo(photo_id(id)).delete
      end

      def url(id, size: nil, **options)
        if size
          size = size.to_s.tr("_", " ").capitalize if size.is_a?(Symbol)
          "https://farm%s.staticflickr.com/%s/%s_%s%s.%s" % size_data(size, id)
        else
          "https://www.flickr.com/photos/#{person.id}/#{photo_id(id)}"
        end
      end

      def clear!
        if album
          album.photos.each(&:delete)
        else
          person.photos.each(&:delete)
        end
      end

      protected

      def photo(id)
        flickr.photos.find(id)
      end

      private

      def size_data(size, id)
        farm, server, photo_id, secret, original_secret, original_format = id.split(/\W/)

        case size
        when "Square 75"  then [farm, server, photo_id, secret, "_s", "jpg"]
        when "Square 150" then [farm, server, photo_id, secret, "_q", "jpg"]
        when "Thumbnail"  then [farm, server, photo_id, secret, "_t", "jpg"]
        when "Small 240"  then [farm, server, photo_id, secret, "_m", "jpg"]
        when "Small 320"  then [farm, server, photo_id, secret, "_n", "jpg"]
        when "Medium 500" then [farm, server, photo_id, secret, "",   "jpg"]
        when "Medium 640" then [farm, server, photo_id, secret, "_z", "jpg"]
        when "Medium 800" then [farm, server, photo_id, secret, "_c", "jpg"]
        when "Large 1024" then [farm, server, photo_id, secret, "_b", "jpg"]
        when "Original"   then [farm, server, photo_id, original_secret, "_o", original_format]
        when "Large 1600", "Large 2048"
          raise Shrine::Error, "#{size.inspect} size isn't available"
        else
          raise Shrine::Error, "unknown size: #{size.inspect}"
        end
      end

      def update_id!(photo, id)
        info_id = "#{photo.farm}-#{photo.server}-#{photo.id}-#{photo.secret}-#{photo["originalsecret"]}.#{photo["originalformat"]}"
        id.replace(info_id)
      end

      def update_metadata!(photo, metadata)
        metadata["flickr"] = photo.attributes if @store_info
      end

      def photo_id(id)
        id.split("-").fetch(2)
      end
    end
  end
end
