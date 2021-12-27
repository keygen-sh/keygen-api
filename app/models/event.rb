# frozen_string_literal: true

class Event < ApplicationRecord
  belongs_to :account
  belongs_to :event_type
  belongs_to :resource,    polymorphic: true
  belongs_to :whodunnit,   polymorphic: true
  belongs_to :request_log, optional: true
end
