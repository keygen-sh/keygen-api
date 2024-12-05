# frozen_string_literal: true

require 'tempfile'
require 'digest'
require 'json'

# see: https://github.com/opencontainers/image-spec/blob/main/image-layout.md
module OciImageLayout
  class Error < StandardError; end
  class LayoutNotFoundError < Error; end
  class IndexNotFoundError < Error; end
  class UnsupportedMediaTypeError < Error; end
  class BadDigestError < Error; end

  def self.parse(io) = Parser.new(io).parse

  class DigestIO < SimpleDelegator
    delegate :digest, :hexdigest, :base64digest, :bubblebabble,
      to: :@digest

    def initialize(io, digest: Digest::SHA256.new)
      raise ArgumentError, 'digest object is required' if digest.nil?

      @digest = digest

      super(io)
    end

    # FIXME(ezekg) mark as written and don't rehash on read/rewind
    def write(*data)
      data.each { @digest << _1 }

      super
    end

    # TODO(ezekg) reset on rewind unless written
    # TODO(ezekg) hash on read
  end

  class Parser
    LAYOUT_FILE = 'oci-layout'
    INDEX_FILE  = 'index.json'

    attr_reader :layout,
                :index

    def initialize(io)
      @fs = Reader.new(io)
    end

    def parse
      @layout = fs.open(LAYOUT_FILE) do |io, path, digest|
        Layout.new(io, size: io.size, path:, digest:, fs:)
      end

      raise LayoutNotFoundError.new, "layout file #{LAYOUT_FILE.inspect} is required" if
        layout.nil?

      @index = fs.open(INDEX_FILE) do |io, path, digest|
        Index.new(io, size: io.size, path:, digest:, fs:)
      end

      raise IndexNotFoundError.new, "index file #{INDEX_FILE.inspect} is required" if
        index.nil?

      self
    end

    def each(&)
      layout.each(&)
      index.each(&)
    end

    private

    attr_reader :fs
  end

  class Reader
    CHUNK_SIZE = 1.megabyte

    attr_reader :entries,
                :digests,
                :paths

    def initialize(io)
      @entries = {}
      @digests = {}
      @paths   = {}

      # Extract all entries to tmp files because chances are these are
      # a Minitar::Reader, and that closes an entry's reader io after
      # reading the entry. This lets us avoid buffering entries into
      # memory, since some of the blobs could be large layers.
      io.each do |entry|
        next unless entry.file?

        tmpfile_io = Tempfile.new(entry.name, binmode: true)
        digest_io  = DigestIO.new(tmpfile_io,
          digest: Digest::SHA256.new,
        )

        while chunk = entry.read(CHUNK_SIZE)
          digest_io.write(chunk)
        end

        digest_io.rewind

        digest = "sha256:#{digest_io.hexdigest}"
        path   = entry.name

        @entries[path] = @entries[digest] = digest_io
        @digests[path] = @digests[digest] = digest
        @paths[path]   = @paths[digest]   = path
      end
    end

    def open(reference)
      entry = entries[reference]
      return if entry.nil?

      digest = digests[reference]
      return if digest.nil?

      path = paths[reference]
      return if path.nil?

      unless block_given?
        return entry.open, path, digest
      end

      yield entry.open, path, digest
    end
  end

  class Blob
    include Enumerable

    attr_reader :media_type,
                :digest,
                :size,
                :path

    def initialize(io, media_type:, digest:, size:, path:, fs:)
      raise UnsupportedMediaTypeError, "unsupported media type: #{media_type.inspect}" unless
        media_type.starts_with?('application/vnd.docker.') ||
        media_type.starts_with?('application/vnd.oci.')

      @io         = io
      @media_type = media_type
      @digest     = digest
      @size       = size
      @path       = path
      @fs         = fs
    end

    def exists?   = io.present?
    def read(...) = (io.read(...) if exists?)
    def seek(...) = (io.seek(...) if exists?)
    def rewind    = (io.rewind if exists?)
    def close     = (io.close if exists?)
    def closed?   = (io.closed? if exists?)
    def to_io     = io
    def open(&)   = fs.open(digest, &)
    def each(&)   = yield_self(&)

    private

    attr_reader :io,
                :fs
  end

  class Layout < Blob
    attr_reader :version

    def initialize(io, **)
      super(io, media_type: 'application/vnd.oci.layout.header.v1+json', **)

      data     = JSON.parse(io.read)
      @version = data['imageLayoutVersion']

      io.rewind
    end
  end

  class Index < Blob
    attr_reader :media_type,
                :manifests

    def initialize(io, fs:, **)
      data       = JSON.parse(io.read)
      media_type = data['mediaType']

      super(io, media_type:, fs:, **)

      @manifests = data['manifests'].map do |manifest|
        Manifest.from_json(manifest, fs:)
      end

      io.rewind
    end

    def each(&)
      super

      manifests.each { _1.each(&) }
    end
  end

  class Descriptor < Blob
    def self.from_json(descriptor, fs:)
      media_type = descriptor['mediaType']
      digest     = descriptor['digest']
      size       = descriptor['size']
      io,
      path,
      real_digest = fs.open(digest)

      # NOTE(ezekg) some multi-platform images have descriptors that point to blobs that
      #             don't exist so we only want to assert this if the blob exists
      unless io.nil?
        raise BadDigestError.new, "expected digest #{digest.inspect} for #{path.inspect} but got #{real_digest.inspect}" unless
          digest == real_digest
      end

      new(io, media_type:, digest:, size:, path:, fs:)
    end
  end

  class Config < Descriptor; end
  class Layer < Descriptor; end

  class Manifest < Descriptor
    attr_reader :annotations,
                :manifests,
                :layers,
                :config

    def initialize(io, fs:, **)
      super(io, fs:, **)

      # TODO(ezekg) add support for annotations? e.g. auto-tagging
      @annotations = []
      @manifests   = []
      @layers      = []
      @config      = nil

      # some blobs may be referenced without being present
      return unless
        exists?

      data = JSON.parse(io.read)
      io.rewind

      if manifests = data['manifests']
        manifests.each do |manifest|
          @manifests << Manifest.from_json(manifest, fs:)
        end
      end

      if layers = data['layers']
        layers.each do |layer|
          @layers << Layer.from_json(layer, fs:)
        end
      end

      if config = data['config']
        @config = Config.from_json(config, fs:)
      end
    end

    def each(&)
      super

      manifests.each { _1.each(&) }
      layers.each { _1.each(&) }
      config&.each(&)
    end
  end
end
