# frozen_string_literal: true

module Compression
  extend ActiveSupport::Concern

  def deflate(data, level: Zlib::BEST_SPEED) = Zlib::Deflate.deflate(data, level)
  def gzip(data, deterministic: true, level: Zlib::BEST_SPEED)
    zipped = StringIO.new
    zipped.set_encoding(Encoding::BINARY)

    gz = Zlib::GzipWriter.new(zipped, level)
    gz.mtime = 0 if deterministic
    gz.write(data)
    gz.close

    zipped.string
  end
end
