# frozen_string_literal: true

module DateRangeable
  extend ActiveSupport::Concern

  MAX_RANGE = 31
  MIN_RANGE = 1

  included do
    scope :for_date_range, -> (date_start, date_end) {
      begin
        date_start = date_start.to_datetime.beginning_of_day
        date_end = date_end.to_datetime.end_of_day
        diff = (date_end.to_i - date_start.to_i) / 1.day

        if diff < MIN_RANGE || diff > MAX_RANGE
          raise Keygen::Error::InvalidParameterError.new(parameter: "date"), "date range must be between #{MIN_RANGE} and #{MAX_RANGE} days (got #{diff})"
        end

        # NB(ezekg) prefer created_date column if supported
        if column_names.include?("created_date")
          where(created_date: date_start..date_end)
        else
          where(created_at: date_start..date_end)
        end
      rescue ArgumentError
        raise Keygen::Error::InvalidParameterError.new(parameter: "date"), "invalid date range"
      end
    }
  end
end
