# frozen_string_literal: true

class Event < ApplicationRecord
  belongs_to :account
  belongs_to :event_type
  belongs_to :resource,
    polymorphic: true
  belongs_to :created_by,
    polymorphic: true
  belongs_to :request_log,
    optional: true

  delegate :requestor,
    to: :request_log,
    allow_nil: true
end
