# frozen_string_literal: true

module Analytics
  module Stat
    class ActiveLicensedUsers
      include ActiveModel::Model
      include ActiveModel::Attributes

      Result = Data.define(:count)

      attribute :account
      attribute :environment # intentionally ignored

      def result
        Result.new(count:)
      end

      def count
        @count ||= account.active_licensed_user_count
      end
    end
  end
end
