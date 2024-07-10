# frozen_string_literal: true

class EventType < ApplicationRecord
  def self.cache_key(event)
    [:event_types, event, CACHE_KEY_VERSION].join ":"
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

  def self.lookup_id_by_event(event) = ids_by_event[event]
  def self.lookup_event_by_id(id)    = events_by_id[id]

  private

  def self.ids_by_event = @ids_by_event ||= all.index_by(&:event).transform_values(&:id)
  def self.events_by_id = @events_by_id ||= all.index_by(&:id).transform_values(&:event)
end
