# Shrine::Storage::Flickr

Provides [Flickr] storage for [Shrine]. Flickr is a photo sharing service which
automatically generates different sizes of uploaded photos.

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

Shrine::Storage::Flickr.new(access_token: ["key", "secret"], user: "12345678@N01")
```

### URL

To generate source URLs, simply pass the name of the size to `#url`:

```rb
user.avatar.url(size: "Medium 500")
user.avatar.url(size: :medium_500) # alternative notation

user.avatar.url(size: "Original")
user.avatar.url(size: :original) # alternative notation
```

All possible sizes are: "Square 75", "Thumbnail", "Square 150", "Small 240",
"Small 320", "Medium 500", "Medium 640", "Medium 800", "Large 1024", and
"Original".

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

You can also add upload options per-upload using the `upload_options` plugin:

```rb
class MyUploader < Shrine
  plugin :upload_options, store: ->(io, context) do
    {
      title: io.original_filename,
      description: context[:record].description,
    }
  end
end
```

### Updating

If you want to update the title and description of the photo, you can use the
`#update` method:

```rb
flickr = Shrine::Storage::Flickr.new(**flickr_options)
# ...
flickr.update(id, title: "Title", description: "Description")
```

### Clearing storage

If you want to delete all photos from this storage, you can call `#clear!`:

```rb
flickr = Shrine::Storage::Flickr.new(**flickr_options)
# ...
flickr.clear!(:confirm)
```

### Linking back

In Flickr's guidelines it states that if you're displaying photos from Flickr
on another webiste, you should always link back to Flickr. This link will be
generated when you don't pass any arguments to `#url`:

```erb
<a href="<%= @user.avatar.url %>">
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
