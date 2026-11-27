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

  # parse the layout, yielding it to the block (if given) and cleaning up
  # any extracted blobs afterwards.
  def self.parse(io)
    parser = Parser.new(io).parse

    return parser unless
      block_given?

    begin
      yield parser
    ensure
      parser.close
    end
  end

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
        Layout.new(size: io.size, path:, digest:, reader:)
      end

      raise LayoutNotFoundError.new, "layout file #{LAYOUT_FILE.inspect} is required" if
        layout.nil?

      @index = reader.open(INDEX_FILE) do |io, path, digest|
        LayoutIndex.new(size: io.size, path:, digest:, layout:)
      end

      raise IndexNotFoundError.new, "index file #{INDEX_FILE.inspect} is required" if
        index.nil?

      self
    end

    def each(&)
      layout.each(&)
      index.each(&)
    end

    # close any open blobs and remove extracted entries from disk
    def close
      layout&.close
      index&.close
      reader.close
    end

    private

    attr_reader :reader
  end

  class Reader
    CHUNK_SIZE = 1.megabyte

    # entry is an extracted file that has been closed, but not yet unlinked,
    # so that it can be reopened on-demand without holding an open fd.
    Entry = Data.define(:tmpfile, :path, :digest) do
      def open(&) = File.open(tmpfile.path, 'rb', &)
      def unlink  = tmpfile.unlink
    end

    attr_reader :entries

    def initialize(io)
      @entries = {}

      # Extract all entries to tmp files because chances are these are
      # a Minitar::Reader, and that closes an entry's reader io after
      # reading the entry. This lets us avoid buffering entries into
      # memory, since some of the blobs could be large layers.
      #
      # Each tmp file is closed immediately after extraction so that we
      # don't hold a file descriptor open per-entry for the lifetime of
      # the reader, which can exhaust the fd limit for large images.
      io.each do |entry|
        next unless entry.file?

        tmpfile   = Tempfile.new(entry.name, binmode: true)
        digest_io = DigestIO.new(tmpfile,
          digest: Digest::SHA256.new,
        )

        begin
          while chunk = entry.read(CHUNK_SIZE)
            digest_io.write(chunk)
          end
        ensure
          tmpfile.close # close fd but keep file on disk until unlinked
        end

        digest = "sha256:#{digest_io.hexdigest}"
        path   = entry.name.delete_prefix('./')

        @entries[path] = @entries[digest] = Entry.new(tmpfile:, path:, digest:)
      end
    rescue
      close # don't leave extracted entries behind on failure

      raise
    end

    def include?(reference) = entries.key?(reference)

    # returns the path and digest for a reference without opening it
    def stat(reference)
      entry = entries[reference]
      return if entry.nil?

      return entry.path, entry.digest
    end

    # opens an independent handle to the entry, which is closed after the
    # block (if given) or must be closed by the caller.
    def open(reference)
      entry = entries[reference]
      return if entry.nil?

      unless block_given?
        return entry.open, entry.path, entry.digest
      end

      entry.open do |io|
        yield io, entry.path, entry.digest
      end
    end

    # removes all extracted entries from disk
    def close
      entries.values.uniq.each(&:unlink)
      entries.clear
    end
  end

  # blob is a pointer to an opaque IO e.g. manifest, layer, etc.
  class Blob
    include Enumerable

    attr_reader :media_type,
                :digest,
                :size,
                :path

    def initialize(media_type:, digest:, size:, path:, reader:)
      @media_type = media_type
      @digest     = digest
      @size       = size
      @path       = path
      @reader     = reader
      @io         = nil
    end

    def exists?   = reader.include?(digest)
    def read(...) = (io.read(...) if exists?)
    def seek(...) = (io.seek(...) if exists?)
    def rewind    = (io.rewind if exists?)
    def closed?   = (@io.nil? || @io.closed?)
    def to_io     = io
    def open(&)   = reader.open(digest, &) # read self
    def each(&)   = yield_self(&)

    # closes the blob's io (if open), it will be reopened on next access
    def close
      @io&.close unless closed?
    ensure
      @io = nil
    end

    private

    attr_reader :reader

    # io is lazily opened so that we don't hold an open fd per-blob
    def io
      return unless exists?

      @io = nil if closed?
      @io ||= reader.open(digest).first
    end
  end

  # image layout is an oci-layout file
  class Layout < Blob
    attr_reader :version

    def initialize(**)
      super(media_type: 'application/vnd.oci.layout.header.v1+json', **)

      data     = open { |io, *| JSON.parse(io.read) }
      @version = data['imageLayoutVersion']
    end

    # defer to reader so that we can open blobs in the layout
    def open(ref = digest, &) = reader.open(ref, &)
    def include?(ref)         = reader.include?(ref)
    def stat(ref)             = reader.stat(ref)
  end

  # descriptor is a pointer to a JSON blob e.g. manifest, config, etc.
  class Descriptor < Blob
    INDEX_MEDIA_TYPES    = %w[application/vnd.oci.image.index.v1+json application/vnd.docker.distribution.manifest.list.v2+json].freeze
    MANIFEST_MEDIA_TYPES = %w[application/vnd.oci.image.manifest.v1+json application/vnd.docker.distribution.manifest.v2+json].freeze

    def self.from_json(data, layout:, **)
      media_type = data['mediaType']
      digest     = data['digest']
      size       = data['size']
      path,
      real_digest = layout.stat(digest)

      # NOTE(ezekg) some multi-platform images have descriptors that point to blobs that
      #             don't exist so we only want to assert this if the blob exists
      unless path.nil?
        raise BadDigestError.new, "expected digest #{digest.inspect} for #{path.inspect} but got #{real_digest.inspect}" unless
          digest == real_digest
      end

      new(media_type:, digest:, size:, path:, layout:, **)
    end

    def initialize(layout:, **) = super(reader: layout, **)
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

    def initialize(layout:, digest:, media_type: nil, **)
      data = layout.open(digest) { |io, *| JSON.parse(io.read) }

      super(media_type: media_type || data['mediaType'], layout:, digest:, **)

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
    end

    def each(&)
      super

      manifests.each { it.each(&) }
    end

    def close
      super

      manifests.each(&:close)
    end
  end

  # index is a nested image index
  class Index < LayoutIndex
    def self.from_descriptor(descriptor, **)
      raise "expected index descriptor but got #{descriptor.media_type}" unless
        descriptor.index?

      new(**descriptor.to_h, **)
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

      new(**descriptor.to_h, **)
    end

    def initialize(layout:, **)
      super(layout:, **)

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

      data = open { |io, *| JSON.parse(io.read) }

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

      layers.each { it.each(&) }
      config&.each(&)
    end

    def close
      super

      layers.each(&:close)
      config&.close
    end
  end

  class Config < Descriptor; end
  class Layer < Descriptor; end
end
