# frozen_string_literal: true

module Analytics
  module Stat
    class Licenses
      include ActiveModel::Model
      include ActiveModel::Attributes

      Result = Data.define(:count)

      attribute :account
      attribute :environment

      def result
        Result.new(count:)
      end

      def count
        @count ||= account.licenses.for_environment(environment).count
      end
    end
  end
end
