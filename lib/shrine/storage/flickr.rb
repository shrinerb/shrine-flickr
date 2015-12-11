require "shrine"
require "flickr-objects"
require "down"

class Shrine
  module Storage
    class Flickr
      attr_reader :person, :flickr, :upload_options, :album

      def initialize(upload_options: {}, user:, access_token:, album: nil)
        @flickr = ::Flickr.new(*access_token)
        @person = @flickr.people.find(user)
        @upload_options = upload_options
        @album = @flickr.sets.find(album) if album
      end

      def upload(io, id, metadata = {})
        options = metadata.delete("flickr") || {}
        options.update(upload_options)

        photo_id = flickr.upload(io, options)
        id.replace(photo_id)
        album.add_photo(id) if album

        metadata["flickr_sizes"] = []
        photo = photo(id).get_sizes!
        photo.available_sizes.each do |size|
          photo.size!(size)
          metadata["flickr_sizes"] << {
            "name"   => size,
            "url"    => photo.source_url,
            "width"  => photo.width,
            "height" => photo.height,
          }
        end
      end

      def download(id)
        raise NotImplementedError, "#download cannot be implemented"
      end

      def open(id)
        raise NotImplementedError, "#open cannot be implemented"
      end

      def exists?(id)
        !!photo(id).get_info!
      rescue ::Flickr::ApiError => error
        raise error if error.code != 1
        false
      end

      def delete(id)
        photo(id).delete
      end

      def url(id, **options)
        raise NotImplementedError, "#url cannot be implemented"
      end

      def clear!(confirm = nil)
        raise Shrine::Confirm unless confirm == :confirm
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
    end
  end
end

class Shrine
  module Plugins
    module Flickr
      module FileMethods
        def download
          if storage.is_a?(Storage::Flickr)
            Down.download(url)
          else
            super
          end
        end

        def url(**options)
          if storage.is_a?(Storage::Flickr)
            size_attribute("url", **options)
          else
            super
          end
        end

        def width(**options)
          size_attribute("width", **options)
        end

        def height(**options)
          size_attribute("height", **options)
        end

        def flickr_url
          "https://www.flickr.com/photos/#{storage.person.id}/#{id}"
        end

        private

        def size_attribute(key, size: "Original")
          size = size.to_s.tr("_", " ").capitalize if size.is_a?(Symbol)
          hash = flickr_sizes.find { |hash| hash["name"] == size }
          hash.fetch(key) if hash
        end

        def io
          if storage.is_a?(Storage::Flickr)
            @io ||= download
          else
            super
          end
        end

        def flickr_sizes
          metadata["flickr_sizes"]
        end
      end
    end
  end

  plugin Plugins::Flickr
end
