# frozen_string_literal: true

module Keygen
  module Import
    module V1
      class Reader < Reader
        def read_chunk_size = read(8)&.unpack1('Q>') || 0
        def read_chunk
          chunk_size = read_chunk_size
          return if chunk_size.zero?

          read(chunk_size)
        end
      end
    end
  end
end
