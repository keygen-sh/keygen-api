# frozen_string_literal: true

require_relative 'import/reader'
require_relative 'import/v1/importer'

module Keygen
  module Import
    extend self

    def import(from:, secret_key: nil)
      reader  = Reader.new(from)
      version = reader.read_version

      importer_class = importer_class_for(version:)
      importer       = importer_class.new(secret_key:)

      importer.import(reader:)
    rescue OpenSSL::Cipher::CipherError
      raise 'secret key is invalid'
    end

    private

    def importer_class_for(version:)
      case version
      when 1
        V1::Importer
      else
        raise "Unsupported import version: #{version}"
      end
    end
  end
end
