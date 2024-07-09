# frozen_string_literal: true

module Keygen
  module Exporter
    module V1
      class Writer
        def initialize(io)    = @io = io
        def to_io             = @io
        def write(data)       = @io.write(data)
        def write_version     = write([1].pack('C')) # first byte is the version
        def write_chunk(data)
          bytesize = [data.bytesize].pack('Q>')

          write(bytesize + data)
        end
      end
    end
  end
end
