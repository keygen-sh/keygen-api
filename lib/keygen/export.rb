# frozen_string_literal: true

require_relative 'export/v1/exporter'

module Keygen
  module Export
    class UnsupportedVersionError < StandardError; end

    VERSION = 1 # the current export version format

    extend self

    def export(account, to: StringIO.new, version: VERSION, secret_key: nil)
      exporter_class = exporter_class_for(version:)
      exporter       = exporter_class.new(account, secret_key:)

      exporter.export(to:)
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
