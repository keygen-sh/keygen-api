module DateRangeable
  extend ActiveSupport::Concern

  included do
    scope :date, -> (date_start, date_end) {
      begin
        limit(nil).where created_at: DateTime.parse(date_start).beginning_of_day..DateTime.parse(date_end).end_of_day
      rescue ArgumentError => e
        raise Keygen::Error::InvalidScopeError.new(parameter: "date"), e
      end
    }
  end
end
