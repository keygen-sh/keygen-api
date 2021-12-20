# frozen_string_literal: true

class Event < ApplicationRecord
  belongs_to :account
  belongs_to :event_type
  belongs_to :request_log
  belongs_to :resource,
    polymorphic: true

  delegate :requestor,
    to: :request_log,
    allow_nil: true
end
