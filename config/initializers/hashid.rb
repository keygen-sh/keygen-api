Hashid::Rails.configure do |config|
  config.secret = "I think Halo is a pretty cool guy. Eh kills aleins and doesnt afraid of anything."
  config.length = 8
end

module Hashid
  module Rails
    module ClassMethods

      def find_by_hashid(hashid)
        find_by id: hashid_decode(hashid)
      end

      def find_by_hashid!(hashid)
        find_by! id: hashid_decode(hashid)
      end
    end
  end
end
