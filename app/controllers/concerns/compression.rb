# frozen_string_literal: true

module Compression
  extend ActiveSupport::Concern

  def deflate(data, **) = Zlib::Deflate.deflate(data, **)
  def gzip(data, deterministic: true, **)
    zipped = StringIO.new
    zipped.set_encoding(Encoding::BINARY)

    gz = Zlib::GzipWriter.new(zipped, Zlib::BEST_COMPRESSION)
    gz.mtime = 0 if deterministic
    gz.write(data)
    gz.close

    zipped.string
  end
end
