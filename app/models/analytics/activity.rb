# frozen_string_literal: true

module Analytics
  class Activity
    Row = Data.define(:event, :count)

    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :account, default: -> { Current.account }
    attribute :environment, default: -> { Current.environment }

    attribute :start_date, default: -> { 2.weeks.ago.to_date }
    attribute :end_date, default: -> { Date.current }
    attribute :resource_type
    attribute :resource_id

    validates :account, presence: true
    validates :pattern, presence: true
    validates :start_date, comparison: { greater_than_or_equal_to: -> { 1.year.ago.to_date } }
    validates :end_date, comparison: { less_than_or_equal_to: -> { Date.current } }

    validate do
      errors.add :pattern, :invalid, message: 'is invalid' if event_types.empty?
    end

    def initialize(pattern, **)
      @pattern = pattern

      super(**)
    end

    def event_type_ids = event_types.ids
    def event_types    = @event_types ||= begin
      return EventType.none if
        pattern.blank?

      types = if pattern.end_with?('.*')
                EventType.where('event LIKE ?', "#{pattern.delete_suffix('.*')}.%")
              else
                EventType.where(event: pattern)
              end

      types.order(:event)
    end

    def rows = @rows ||= begin
      counts = counter.count(event_type_ids:, start_date:, end_date:, resource_type:, resource_id:)

      event_types.map do |event_type|
        Row.new(event: event_type.event, count: counts[event_type.id].to_i)
      end
    end

    delegate :as_json, :to_json,
      to: :rows

    private

    attr_reader :pattern

    def counter = Counters::EventTypes.new(account:, environment:)
  end
end
