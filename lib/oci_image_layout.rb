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

  class Parser
    LAYOUT_FILE = 'oci-layout'
    INDEX_FILE  = 'index.json'

    attr_reader :layout,
                :index

    def initialize(io)
      @reader = Reader.new(io)
    end

    def parse
      @layout = reader.open(LAYOUT_FILE) do |io, path, digest|
        Layout.new(io, size: io.size, path:, digest:, reader:)
      end

      raise LayoutNotFoundError.new, "layout file #{LAYOUT_FILE.inspect} is required" if
        layout.nil?

      @index = reader.open(INDEX_FILE) do |io, path, digest|
        LayoutIndex.new(io, size: io.size, path:, digest:, layout:)
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

    attr_reader :reader
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
        path   = entry.name.delete_prefix('./')

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

  # blob is a pointer to an opaque IO e.g. manifest, layer, etc.
  class Blob
    include Enumerable

    attr_reader :media_type,
                :digest,
                :size,
                :path

    def initialize(io, media_type:, digest:, size:, path:, reader:)
      @io         = io
      @media_type = media_type
      @digest     = digest
      @size       = size
      @path       = path
      @reader     = reader
    end

    def exists?   = io.present?
    def read(...) = (io.read(...) if exists?)
    def seek(...) = (io.seek(...) if exists?)
    def rewind    = (io.rewind if exists?)
    def close     = (io.close if exists?)
    def closed?   = (io.closed? if exists?)
    def to_io     = io
    def open(&)   = reader.open(digest, &) # read self
    def each(&)   = yield_self(&)

    private

    attr_reader :reader,
                :io
  end

  # image layout is an oci-layout file
  class Layout < Blob
    attr_reader :version

    def initialize(io, **)
      super(io, media_type: 'application/vnd.oci.layout.header.v1+json', **)

      data     = JSON.parse(io.read)
      @version = data['imageLayoutVersion']

      io.rewind
    end

    # open defers to reader so that we can open blobs in the layout
    def open(ref, &) = reader.open(ref, &)
  end

  # descriptor is a pointer to a JSON blob e.g. manifest, config, etc.
  class Descriptor < Blob
    INDEX_MEDIA_TYPES    = %w[application/vnd.oci.image.index.v1+json application/vnd.docker.distribution.manifest.list.v2+json].freeze
    MANIFEST_MEDIA_TYPES = %w[application/vnd.oci.image.manifest.v1+json application/vnd.docker.distribution.manifest.v2+json].freeze

    def self.from_json(data, layout:, **)
      media_type = data['mediaType']
      digest     = data['digest']
      size       = data['size']
      io,
      path,
      real_digest = layout.open(digest)

      # NOTE(ezekg) some multi-platform images have descriptors that point to blobs that
      #             don't exist so we only want to assert this if the blob exists
      unless io.nil?
        raise BadDigestError.new, "expected digest #{digest.inspect} for #{path.inspect} but got #{real_digest.inspect}" unless
          digest == real_digest
      end

      new(io, media_type:, digest:, size:, path:, layout:, **)
    end

    def initialize(*, layout:, **) = super(*, reader: layout, **)
    alias :layout :reader

    def index?    = media_type.in?(INDEX_MEDIA_TYPES)
    def manifest? = media_type.in?(MANIFEST_MEDIA_TYPES)

    def to_index    = Index.from_descriptor(self, layout:)
    def to_manifest = Manifest.from_descriptor(self, layout:)
    def to_h        = { media_type:, digest:, size:, path: }
  end

  # layout index is an index.json file
  class LayoutIndex < Descriptor
    attr_reader :schema_version,
                :media_type,
                :manifests

    def initialize(io, layout:, **)
      data       = JSON.parse(io.read)
      media_type = data['mediaType']

      super(io, media_type:, layout:, **)

      @schema_version = data['schemaVersion']

      # NOTE(ezekg) unreferenced blobs are NOT stored since we cannot determine their media type
      @manifests = data['manifests'].map do |manifest|
        descriptor = Descriptor.from_json(manifest, layout:)

        case
        when descriptor.index? # nested index
          descriptor.to_index
        when descriptor.manifest?
          descriptor.to_manifest
        else
          descriptor
        end
      end

      io.rewind
    end

    def each(&)
      super

      manifests.each { _1.each(&) }
    end
  end

  # index is a nested image index
  class Index < LayoutIndex
    def self.from_descriptor(descriptor, **)
      raise "expected index descriptor but got #{descriptor.media_type}" unless
        descriptor.index?

      new(descriptor.to_io, **descriptor.to_h, **)
    end
  end

  # manifest is an image manifest referenced by an image index
  class Manifest < Descriptor
    attr_reader :annotations,
                :subject,
                :manifests,
                :layers,
                :config

    def self.from_descriptor(descriptor, **)
      raise "expected manifest descriptor but got #{descriptor.media_type}" unless
        descriptor.manifest?

      new(descriptor.to_io, **descriptor.to_h, **)
    end

    def initialize(io, layout:, **)
      super(io, layout:, **)

      # TODO(ezekg) add support for annotations? e.g. auto-tagging
      @annotations = []

      # TODO(ezekg) add support for subject? e.g. referrers
      @subject = nil

      @manifests = []
      @layers    = []
      @config    = nil

      # some blobs may be referenced without being present
      return unless
        exists?

      data = JSON.parse(io.read)
      io.rewind

      if layers = data['layers']
        layers.each do |layer|
          @layers << Layer.from_json(layer, layout:)
        end
      end

      if config = data['config']
        @config = Config.from_json(config, layout:)
      end
    end

    def each(&)
      super

      layers.each { _1.each(&) }
      config&.each(&)
    end
  end

  class Config < Descriptor; end
  class Layer < Descriptor; end
end
