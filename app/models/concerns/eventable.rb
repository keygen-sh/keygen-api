# frozen_string_literal: true

# TODO(ezekg) Extract out to an `eventor` gem?
module Eventable
  extend ActiveSupport::Concern

  class AssociationTooDeepError < StandardError; end
  class LockNotAcquiredError < StandardError; end
  class LockTimeoutError < StandardError; end

  EVENTABLE_WILDCARD_SENTINEL  = '9f3bc5d9'
  EVENTABLE_CALLBACK_PREFIX    = '__eventable_'
  EVENTABLE_LOCK_PREFIX        = 'eventable:lock:'
  EVENTABLE_LOCK_TIMEOUT       = 30.seconds
  EVENTABLE_LOCK_TTL           = 60.seconds
  EVENTABLE_IDEMPOTENCY_PREFIX = 'eventable:idem:'
  EVENTABLE_IDEMPOTENCY_TTL    = 24.hours

  included do
    extend ActiveModel::Callbacks

    def notify!(event:, idempotency_key: nil)
      callback_key = self.class.callback_key_for_event(event)
      callbacks    = matching_callbacks(callback_key)
      redis        = Rails.cache.redis

      # Skip if an :idempotency_key was provided and has already been processed
      if idempotency_key.present?
        idem_key = idem_key_for_idempotency_key(idempotency_key)

        return unless
          redis.with { |c| c.set(idem_key, 1, nx: true, ex: EVENTABLE_IDEMPOTENCY_TTL) }
      end

      # Run the callbacks
      statuses = callbacks.map do |key|
        if ok = run_callbacks(key)
          event    = key.to_s.delete_prefix(EVENTABLE_CALLBACK_PREFIX)
          lock_key = lock_key_for_event(event)

          # Release the lock
          redis.with { |c| c.del(lock_key) }

          ok
        end
      end
    rescue
      if statuses&.none? && idempotency_key.present?
        idem_key = idem_key_for_idempotency_key(idempotency_key)

        # Release the idempotency lock on complete failure
        redis.with { |c| c.del(idem_key) }
      end

      raise
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
      EVENTABLE_LOCK_PREFIX + "#{self.id}:#{self.class.parameterized_callback_key(event)}"
    end

    def idem_key_for_idempotency_key(key)
      EVENTABLE_IDEMPOTENCY_PREFIX + "#{self.id}:#{key}"
    end
  end

  module ClassMethods
    def on_event(event, callback, through: nil, **kwargs)
      callback_key = callback_key_for_event(event)

      define_model_callbacks(callback_key, only: :before) unless
        respond_to?(:"before_#{callback_key}")

      if reflection = reflect_on_association(through)
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

    def on_atomic_event(event, callback, wait_on_lock_error: false, raise_on_lock_error: false, **kwargs)
      acquire_lock = proc do
        redis = Rails.cache.redis
        key   = lock_key_for_event(event)
        time  = Time.current.to_f
        nonce = "#{Process.pid}:#{time}"

        loop do
          break true if
            redis.with { |c| c.set(key, nonce, nx: true, ex: EVENTABLE_LOCK_TTL) }

          delta_time = Time.current.to_f - time
          timed_out  = delta_time > EVENTABLE_LOCK_TIMEOUT

          if raise_on_lock_error
            raise LockNotAcquiredError, 'failed to acquire lock' unless wait_on_lock_error
            raise LockTimeoutError, 'lock timeout' if timed_out
          else
            break false unless wait_on_lock_error
            break false if timed_out
          end
        end
      end

      # Since we're using :if to acquire our lock below, we're going to
      # append our locking proc to any :if params.
      kwargs.merge!(
        if: Array(kwargs.delete(:if)).push(acquire_lock)
      )

      on_event(event, callback, **kwargs)
    end

    def callback_key_for_event(event)
      key = EVENTABLE_CALLBACK_PREFIX + parameterized_callback_key(event)

      key.to_sym
    end

    def parameterized_callback_key(event)
      event.to_s.sub('*', EVENTABLE_WILDCARD_SENTINEL)
                .underscore
                .parameterize(separator: '_')
    end
  end
end
