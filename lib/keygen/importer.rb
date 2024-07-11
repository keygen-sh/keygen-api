# frozen_string_literal: true

require_relative 'importer/reader'
require_relative 'importer/version_reader'
require_relative 'importer/v1/importer'

module Keygen
  module Importer
    class UnsupportedVersionError < StandardError; end
    class InvalidSecretKeyError < StandardError; end

    extend self

    def import(from:, secret_key: nil)
      version_reader = VersionReader.new(from)
      version        = version_reader.read_version

      importer_class = importer_class_for(version:)
      importer       = importer_class.new(secret_key:)

      importer.import(from:)
    rescue OpenSSL::Cipher::CipherError
      raise InvalidSecretKeyError.new, 'Secret key is invalid'
    end

    private

    def importer_class_for(version:)
      case version
      when 1
        V1::Importer
      else
        raise UnsupportedVersionError.new, "Unsupported import version: #{version}"
      end
    end
  end
end
