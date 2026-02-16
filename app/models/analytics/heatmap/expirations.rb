# frozen_string_literal: true

module Analytics
  module Heatmap
    class Expirations
      include ActiveModel::Model
      include ActiveModel::Attributes

      START_DAY_OF_WEEK = :sunday

      attribute :account
      attribute :environment
      attribute :start_date, default: -> { Date.current }
      attribute :end_date, default: -> { 364.days.from_now.to_date }

      validates :account, presence: true
      validates :start_date, comparison: { greater_than_or_equal_to: -> { 1.month.ago.to_date } }
      validates :end_date, comparison: { less_than_or_equal_to: -> { 1.year.from_now.to_date } }

      def result
        @result ||= build_heatmap
      end

      private

      def build_heatmap
        grid_start  = start_date.beginning_of_week(START_DAY_OF_WEEK)
        expirations = fetch_license_expirations_by_date
        max_count   = expirations.values.max || 1

        (start_date..end_date).map do |date|
          offset = (date - grid_start).to_i
          count  = expirations[date] || 0
          temp   = (count.to_f / max_count).round(1)

          Cell.new(
            x: offset / 7,
            y: date.wday,
            temperature: temp,
            count:,
            date:,
          )
        end
      end

      def fetch_license_expirations_by_date
        account.licenses.unordered
                        .for_environment(environment)
                        .where.not(expiry: nil)
                        .where(expiry: start_date.beginning_of_day..end_date.end_of_day)
                        .group(Arel.sql('DATE(expiry)'))
                        .count
      end
    end
  end
end
