# frozen_string_literal: true

require_relative '../reader'

module Keygen
  module Importer
    module V1
      class Reader < Reader
        def read_chunk_size = read(8)&.unpack1('Q>') || 0
        def read_chunk
          chunk_size = read_chunk_size
          return if chunk_size.zero?

          chunk = read(chunk_size)

          unless chunk.size == chunk_size
            raise InvalidChunkError.new, 'chunk is invalid'
          end

          chunk
        end
      end
    end
  end
end
