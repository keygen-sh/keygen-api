# frozen_string_literal: true

module Analytics
  class ExpirationsHeatmapQuery < BaseQuery
    Result = Data.define(:date, :x, :y, :temperature, :count)

    START_DAY_OF_WEEK = :sunday

    def initialize(account:, environment: nil, start_date: Date.current, end_date: 364.days.from_now.to_date)
      @account     = account
      @environment = environment
      @start_date  = start_date
      @end_date    = [end_date, 1.year.from_now.to_date].min
    end

    def call
      expirations = fetch_license_expirations_by_date
      max_count   = expirations.values.max || 1

      grid_start = start_date.beginning_of_week(START_DAY_OF_WEEK)
      dates      = start_date..end_date

      dates.map do |date|
        offset = (date - grid_start).to_i
        count  = expirations[date] || 0
        temp   = (count.to_f / max_count).round(1)

        Result.new(
          x: offset / 7,
          y: date.wday,
          temperature: temp,
          count:,
          date:,
        )
      end
    end

    private

    attr_reader :account,
                :environment,
                :start_date,
                :end_date

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
