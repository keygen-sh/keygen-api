# frozen_string_literal: true

class EventLog < ApplicationRecord
  belongs_to :account
  belongs_to :event_type
  belongs_to :resource,
    polymorphic: true,
    optional: true
  belongs_to :whodunnit,
    polymorphic: true,
    optional: true
  belongs_to :request_log,
    optional: true
end
