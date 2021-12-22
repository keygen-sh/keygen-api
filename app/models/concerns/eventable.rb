# frozen_string_literal: true

# TODO(ezekg) Extract out to an `eventor` gem?
module Eventable
  extend ActiveSupport::Concern

  class AssociationTooDeepError < StandardError; end

  EVENTABLE_WILDCARD_SENTINEL = SecureRandom.hex(4)
  EVENTABLE_CALLBACK_PREFIX   = '__eventable_'
  EVENTABLE_LOCK_PREFIX       = 'eventable:lock:'
  EVENTABLE_LOCK_TTL          = 60.seconds

  included do
    extend ActiveModel::Callbacks

    def notify!(event:)
      callback_key = self.class.callback_key_for_event(event)
      matches      = matching_callbacks(callback_key)

      matches.map { |k| run_callbacks(k) }

      redis = Rails.cache.redis
      key   = lock_key_for_event(event)

      redis.with { |c| c.del(key) }
    end

    private

    def matching_callbacks(pattern)
      callbacks = __callbacks.select do |key|
        case
        when key.starts_with?(EVENTABLE_CALLBACK_PREFIX + EVENTABLE_WILDCARD_SENTINEL)
          suffix = key.to_s.remove(EVENTABLE_CALLBACK_PREFIX + EVENTABLE_WILDCARD_SENTINEL)

          pattern.ends_with?(suffix)
        when key.ends_with?(EVENTABLE_WILDCARD_SENTINEL)
          prefix = key.to_s.remove(EVENTABLE_WILDCARD_SENTINEL)

          pattern.starts_with?(prefix)
        else
          pattern == key
        end
      end

      callbacks.keys
    end

    def lock_key_for_event(event)
      EVENTABLE_LOCK_PREFIX + "#{self.id}:#{event}"
    end
  end

  module ClassMethods
    def on_event(event, callback, **kwargs)
      callback_key = callback_key_for_event(event)

      define_model_callbacks(callback_key, only: :before) unless
        respond_to?(:"after_#{callback_key}")

      if reflection = reflect_on_association(kwargs.delete(:through))
        raise AssociationTooDeepError, 'association is too deep (only immediate associations are allowed for :through)' if
          reflection.is_a?(ActiveRecord::Reflection::ThroughReflection)

        # Wire up the association to listen for the target event and notify
        # the parent (making the association Eventable if not already)
        klass = reflection.klass
        cb    = -> do
          next unless
            reflection.inverse_of.present?

          inverse = send(reflection.inverse_of.name)

          inverse.notify!(event: event)
        end

        klass.include(Eventable) unless
          klass < Eventable

        klass.on_event(event, cb, **kwargs)
      end

      set_callback(callback_key, :before, callback, **kwargs)
    end

    def on_atomic_event(event, callback, **kwargs)
      acquire_lock = -> {
        redis = Rails.cache.redis
        key   = lock_key_for_event(event)
        nonce = "#{Process.pid}:#{Time.current.to_f}"

        redis.with { |c| c.set(key, nonce, nx: true, px: EVENTABLE_LOCK_TTL) }
      }

      # Since we're using :if to acquire our lock below, we're going to
      # append our locking proc to any :if params.
      kwargs.merge!(
        if: Array(kwargs.delete(:if)).push(acquire_lock)
      )

      on_event(event, callback, **kwargs)
    end

    def callback_key_for_event(event)
      key = EVENTABLE_CALLBACK_PREFIX +
        event.to_s.sub('*', EVENTABLE_WILDCARD_SENTINEL)
                  .underscore
                  .parameterize(separator: '_')

      key.to_sym
    end
  end
end
