# frozen_string_literal: true

module Analytics
  class Request
    Row = Data.define(:date, :count)

    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :account, default: -> { Current.account }
    attribute :environment, default: -> { Current.environment }

    attribute :start_date, default: -> { 2.weeks.ago.to_date }
    attribute :end_date, default: -> { Date.current }

    validates :account, presence: true
    validates :start_date, comparison: { greater_than_or_equal_to: -> { 1.year.ago.to_date } }
    validates :end_date, comparison: { less_than_or_equal_to: -> { Date.current } }

    def rows = @rows ||= begin
      counts = counter.count(start_date:, end_date:)

      (start_date..end_date).map do |date|
        count = counts[date].to_i

        Row.new(date:, count:)
      end
    end

    delegate :as_json, :to_json,
      to: :rows

    private

    def counter = Counters::Requests.new(account:, environment:)
  end
end
