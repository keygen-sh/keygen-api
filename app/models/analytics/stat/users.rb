# frozen_string_literal: true

module Analytics
  module Stat
    class Users
      include ActiveModel::Model
      include ActiveModel::Attributes

      Result = Data.define(:count)

      attribute :account
      attribute :environment

      def result
        Result.new(count:)
      end

      def count
        @count ||= account.users.for_environment(environment)
                                .with_roles(:user)
                                .count
      end
    end
  end
end
