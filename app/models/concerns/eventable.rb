# frozen_string_literal: true

# TODO(ezekg) Extract out to an `eventor` gem?
module Eventable
  extend ActiveSupport::Concern

  class AssociationTooDeepError < StandardError; end
  class LockNotAcquiredError < StandardError; end
  class LockTimeoutError < StandardError; end

  EVENTABLE_WILDCARD_SENTINEL  = '9f3bc5d9' # Predetermined value since we're distributed
  EVENTABLE_CALLBACK_PREFIX    = '__eventable_'
  EVENTABLE_IDEMPOTENCY_PREFIX = 'eventable:idem:'
  EVENTABLE_IDEMPOTENCY_TTL    = 24.hours
  EVENTABLE_LOCK_PREFIX        = 'eventable:lock:'
  EVENTABLE_LOCK_TIMEOUT       = 30.seconds
  EVENTABLE_LOCK_TTL           = 60.seconds
  EVENTABLE_LOCK_CMDs          = {
    release_lock: <<~LUA
      if redis.call('get', KEYS[1]) == ARGV[1] then
        return redis.call('del', KEYS[1])
      else
        return 0
      end
    LUA
  }

  included do
    extend ActiveModel::Callbacks

    def notify!(event:, idempotency_key: nil)
      callback_key = self.class.callback_key_for_event(event)
      callbacks    = matching_callbacks(callback_key)

      # Skip if an :idempotency_key was provided and has already been processed
      if idempotency_key.present?
        return unless
          acquire_idem_for_event!(event)
      end

      # Run the callbacks
      statuses = callbacks.map do |(key)|
        run_callbacks(key) do
          e = key.to_s.delete_prefix(EVENTABLE_CALLBACK_PREFIX)

          release_lock_for_event!(e)
        end
      end
    rescue
      # Release the idempotency lock on complete failure
      release_idem_for_event!(event) if
        idempotency_key.present? &&
        statuses&.none?

      raise
    end

    private

    class_attribute :__eventable_lock_values,
      instance_writer: false,
      default: {}

    class_attribute :__eventuable_lua_shas,
      instance_writer: false,
      default: {}

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

      callbacks
    end

    def lock_key_for_event(event)
      EVENTABLE_LOCK_PREFIX + "#{self.id}:#{self.class.parameterized_callback_key(event)}"
    end

    def idem_key_for_idempotency_key(key)
      EVENTABLE_IDEMPOTENCY_PREFIX + "#{self.id}:#{key}"
    end

    def lock_key_value(key)
      __eventable_lock_values[key]
    end

    def load_lua_cmd(cmd)
      redis = Rails.cache.redis

      return __eventuable_lua_shas[cmd] if
        __eventuable_lua_shas.key?(cmd)

      __eventuable_lua_shas[cmd] =
        redis.with { |c| c.script(:load, EVENTABLE_LOCK_CMDs[cmd]) }
    end

    def acquire_lock_for_event!(event, wait_on_lock_error:, raise_on_lock_error:)
      redis = Rails.cache.redis
      key   = lock_key_for_event(event)

      Timeout.timeout(EVENTABLE_LOCK_TIMEOUT) do
        loop do
          val = SecureRandom.hex(8)
          if redis.with { |c| c.set(key, val, nx: true, ex: EVENTABLE_LOCK_TTL) }
            __eventable_lock_values[key] = val

            return true
          end

          if raise_on_lock_error
            raise LockNotAcquiredError, 'failed to acquire lock' unless
              wait_on_lock_error
          end

          return false unless
            wait_on_lock_error

          sleep rand(0.1..1.0)
        end
      end
    rescue Timeout::Error
      raise LockTimeoutError, 'lock timeout' if
        raise_on_lock_error
    end

    def release_lock_for_event!(event)
      redis = Rails.cache.redis
      sha   = load_lua_cmd(:release_lock)
      key   = lock_key_for_event(event)
      val   = lock_key_value(key)

      redis.with { |c| !c.evalsha(sha, keys: [key], argv: [val]).zero? }
    end

    def acquire_idem_for_event!(event)
      redis = Rails.cache.redis
      key   = idem_key_for_idempotency_key(idempotency_key)

      redis.with { |c| c.set(key, 1, nx: true, ex: EVENTABLE_IDEMPOTENCY_TTL) }
    end

    def release_idem_for_event!(event)
      redis = Rails.cache.redis
      key   = idem_key_for_idempotency_key(idempotency_key)

      redis.with { |c| !c.del(key).zero? }
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
      # Since we're using :if to acquire our lock below, we're going to
      # append our locking proc to any :if params.
      kwargs.merge!(
        if: Array(kwargs.delete(:if))
              .push(Proc.new {
                acquire_lock_for_event!(event,
                  wait_on_lock_error: wait_on_lock_error,
                  raise_on_lock_error: raise_on_lock_error
                )
              })
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
