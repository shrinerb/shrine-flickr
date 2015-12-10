# Shrine::Flickr

Provides [Flickr] storage for [Shrine].

## Installation

```ruby
gem "shrine-flickr"
```

## Usage

First you need to assign API key and shared secret to the Flickr client:

```rb
require "flickr-objects"

Flickr.configure do |config|
  config.api_key = "..."
  config.shared_secret = "..."
end
```

Afterwards you need to authenticate the account on which you want to upload
photos, see [`Flickr::OAuth`] on how you can do that. After you've obtained the
access token, you can assign it to the storage:

```rb
require "shrine/storage/flickr"

Shrine::Storage::Flickr.new(access_token: ["key", "secret"])
```

### URL options

After the image is uploaded, available sizes and their URLs will be saved to
file's `#metadata`:

```rb
user.avatar.metadata #=>
# {
#   "flickr_sizes" => {
#     "Square 75" => "https://farm6.staticflickr.com/5687/23578693711_ab9745cfd0_s.jpg",
#     "Thumbnail" => "https://farm6.staticflickr.com/5687/23578693711_ab9745cfd0_t.jpg",
#     "Original" => "https://farm6.staticflickr.com/5687/23578693711_0bf01bb96a_o.jpg",
#   }
# }
```

You can pass in the name of the size as a URL option:

```rb
user.avatar.url(size: "Medium 500")
user.avatar.url(size: :medium_500)
```

All possible sizes are: "Square 75", "Thumbnail", "Square 150", "Small 240",
"Small 320", "Medium 500", "Medium 640", "Medium 800", "Large 1024", "Large
1600", "Large 2048" and "Original".

### Album

You can choose to upload all your photos in an album by giving the album ID:

```rb
Shrine::Storage::Flickr.new(album: "934891234")
```

### Upload options

If you want to pass in additional attributes to the [Flickr's upload API], you
can pass in the `:upload_options` option:

```rb
Shrine::Storage::Flickr.new(upload_options: {hidden: 1})
```

Alternatively, if you would like to do it per-file, you can override
`#extract_metadata` in your uploader, and add upload options under the "flickr"
key:

```rb
class MyUploader < Shrine
  def extract_metadata(io, context)
    metadata = super
    metadata["flickr"] = {
      title: io.original_filename,
      description: context[:record].description,
    }
    metadata
  end
end
```

### Clearing storage

If you want to delete all photos from this storage, you can call `#clear!`:

```rb
flickr = Shrine::Storage::Flickr.new(access_token: ["...", "..."])
# ...
flickr.clear!(:confirm)
```

### Linking back

In Flickr's guidelines it states that if you're displaying photos from Flickr
on another webiste, you should always link back to Flickr. For that you can
use `#flickr_url`:

```erb
<a href="<%= @user.avatar.flickr_url %>">
  <img src="<%= @user.avatar.url(size: "Small 320") %>">
</a>
```

## Contributing

First you need to create an `.env` file where you will store your credentials:

```sh
# .env
FLICKR_API_KEY="..."
FLICKR_SHARED_SECRET="..."
FLICKR_ACCESS_TOKEN_KEY="..."
FLICKR_ACCESS_TOKEN_SECRET="..."
FLICKR_USER="..." # The user ID, e.g. "94384331@N07"
```

Afterwards you can run the tests:

```sh
$ bundle exec rake test
```

## License

[MIT](http://opensource.org/licenses/MIT)

[Flickr]: https://www.flickr.com/
[Shrine]: https://github.com/janko-m/shrine
[`Flickr::OAuth`]: http://www.rubydoc.info/github/janko-m/flickr-objects/master/Flickr/OAuth
[Flickr's upload API]: https://www.flickr.com/services/api/upload.api.html
