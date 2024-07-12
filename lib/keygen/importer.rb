# frozen_string_literal: true

require_relative 'importer/reader'
require_relative 'importer/version_reader'
require_relative 'importer/v1/importer'

module Keygen
  module Importer
    class UnsupportedVersionError < StandardError; end
    class InvalidSecretKeyError < StandardError; end
    class InvalidDataError < StandardError; end
    class InvalidChunkError < InvalidDataError; end

    extend self

    def import(from:, secret_key: nil)
      version_reader = VersionReader.new(from)
      version        = version_reader.read_version

      importer_class = importer_class_for(version:)
      importer       = importer_class.new(secret_key:)

      importer.import(from:)
    end

    private

    def importer_class_for(version:)
      case version
      when 1
        V1::Importer
      else
        raise UnsupportedVersionError.new, "unsupported import version: #{version}"
      end
    end
  end
end
