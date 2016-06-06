Hashid::Rails.configure do |config|
  config.secret = 'qLW2ZgYbW4ndzmGfHmfqffC7d2cTVJ'
  config.length = 8
end

module Hashid
  module Rails
    module ClassMethods

      def find_by_hashid(hashid)
        find_by(id: hashid_decode(hashid))
      end

      def find_by_hashid!(hashid)
        find_by!(id: hashid_decode(hashid))
      end
    end
  end
end
