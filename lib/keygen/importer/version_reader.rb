# frozen_string_literal: true

require_relative 'reader'

module Keygen
  module Importer
    class VersionReader < Reader
      def read_version = read(1).unpack1('C') # first byte is the version
    end
  end
end
