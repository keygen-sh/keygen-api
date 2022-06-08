# frozen_string_literal: true

class Metric < ApplicationRecord
  include DateRangeable
  include Limitable
  include Orderable
  include Pageable

  belongs_to :account
  belongs_to :event_type

  validates :data, presence: true

  scope :with_events, -> (*events) { where(event_type_id: EventType.where(event: events).pluck(:id)) }
end
