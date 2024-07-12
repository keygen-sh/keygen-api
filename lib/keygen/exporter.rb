# frozen_string_literal: true

require 'digest'

require_relative 'exporter/writer'
require_relative 'exporter/v1/exporter'

module Keygen
  module Exporter
    class UnsupportedVersionError < StandardError; end

    # the current export version format
    VERSION = 1

    extend self

    def export(account, to: StringIO.new, version: VERSION, digest: Digest::SHA256.new, secret_key: nil)
      exporter_class = exporter_class_for(version:)
      exporter       = exporter_class.new(account, secret_key:)

      exporter.export(to:, digest:)
    end

    private

    def exporter_class_for(version:)
      case version
      when 1
        V1::Exporter
      else
        raise UnsupportedVersionError.new, "Unsupported export version: #{version}"
      end
    end
  end
end
