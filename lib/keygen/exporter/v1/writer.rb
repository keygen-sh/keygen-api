# frozen_string_literal: true

require_relative '../writer'

module Keygen
  module Exporter
    module V1
      class Writer < Writer
        def write_version = super(1)
        def write_chunk(data)
          bytesize = [data.bytesize].pack('Q>')

          write(bytesize + data)
        end
      end
    end
  end
end
