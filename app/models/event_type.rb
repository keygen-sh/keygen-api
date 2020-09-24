# frozen_string_literal: true

class EventType < ApplicationRecord
  def self.cache_key(event)
    [:event_types, event].join ":"
  end

  def cache_key
    EventType.cache_key event
  end

  def self.clear_cache!(event)
    key = EventType.cache_key event

    Rails.cache.delete key
  end

  def clear_cache!
    EventType.clear_cache! event
  end
end
