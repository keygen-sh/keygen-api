module Keygen
  module Store
    class Request
      def self.initialize!
        Thread.current[:keygen_request_store] ||= {}
      end

      def self.clear!
        Thread.current[:keygen_request_store] = {}
      end

      def self.store
        Thread.current[:keygen_request_store]
      end
    end
  end
end