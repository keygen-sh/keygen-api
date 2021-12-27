# frozen_string_literal: true

# TODO(ezekg) Extract out to an `eventor` gem?
module Eventable
  extend ActiveSupport::Concern

  class BadAssociationError < StandardError; end
  class LockNotAcquiredError < StandardError; end
  class LockTimeoutError < StandardError; end

  EVENTABLE_WILDCARD_SENTINEL  = '9f3bc5d9' # Predetermined value since we're distributed
  EVENTABLE_CALLBACK_PREFIX    = '__eventable_'
  EVENTABLE_IDEMPOTENCY_PREFIX = 'eventable:idem:'
  EVENTABLE_IDEMPOTENCY_TTL    = 24.hours
  EVENTABLE_LOCK_PREFIX        = 'eventable:lock:'
  EVENTABLE_LOCK_TIMEOUT       = 30.seconds
  EVENTABLE_LOCK_TTL           = 60.seconds
  EVENTABLE_LUA_SHASUMS        = {}

  included do
    extend ActiveModel::Callbacks

    def notify_of_event!(event:, idempotency_key: nil)
      callback_key = self.class.callback_key_for_event(event)
      callbacks    = matching_callbacks(callback_key)

      # Skip if an :idempotency_key was provided and has already been processed
      if idempotency_key.present?
        return unless
          acquire_idempotency_lock!(idempotency_key)
      end

      # Run the callbacks
      statuses = callbacks.map do |(key)|
        run_callbacks(key) do
          e = key.to_s.delete_prefix(EVENTABLE_CALLBACK_PREFIX)

          release_event_lock!(e)
        end
      end
    rescue
      # Release the idempotency lock on complete failure
      release_idempotency_lock!(idempotency_key) if
        idempotency_key.present? &&
        statuses&.none?

      raise
    end

    def listens_to?(event)
      callback_key = self.class.callback_key_for_event(event)
      callbacks    = matching_callbacks(callback_key)

      callbacks.any?
    end

    private

    class_attribute :__eventable_lock_checksums,
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

    def event_lock_key(event)
      EVENTABLE_LOCK_PREFIX + "#{self.id}:#{self.class.parameterized_callback_key(event)}"
    end

    def idempotency_lock_key(key)
      EVENTABLE_IDEMPOTENCY_PREFIX + "#{self.id}:#{key}"
    end

    def current_lock_checksum(key)
      __eventable_lock_checksums[key]
    end

    def acquire_event_lock!(event, raise_on_lock_error:, wait_on_lock:)
      redis = Rails.cache.redis
      key   = event_lock_key(event)

      Timeout.timeout(EVENTABLE_LOCK_TIMEOUT) do
        loop do
          checksum = SecureRandom.hex
          if redis.with { |c| c.set(key, checksum, nx: true, ex: EVENTABLE_LOCK_TTL) }
            __eventable_lock_checksums[key] = checksum

            return true
          end

          if raise_on_lock_error
            raise LockNotAcquiredError, 'failed to acquire lock' unless
              wait_on_lock
          end

          return false unless
            wait_on_lock

          sleep rand(0.1..1.0)
        end
      end
    rescue Timeout::Error
      # Always release the lock for the current checksum, since Timeout
      # could (although unlikely), raise after we obtain a lock but before
      # we exit the method. This makes sure the lock is released.
      release_event_lock!(key, checksum: checksum)

      raise LockTimeoutError, 'lock timeout' if
        raise_on_lock_error
    end

    def release_event_lock!(event, checksum: nil)
      redis      = Rails.cache.redis
      key        = event_lock_key(event)
      checksum ||= current_lock_checksum(key)

      # Redlock algorithm (see https://redis.io/topics/distlock)
      cmd = <<~LUA
        if redis.call('get', KEYS[1]) == ARGV[1] then
          return redis.call('del', KEYS[1])
        else
          return 0
        end
      LUA

      shasum =
        (EVENTABLE_LUA_SHASUMS[:delif] ||= redis.with { |c| c.script(:load, cmd) })

      redis.with { |c| !c.evalsha(shasum, keys: [key], argv: [checksum]).zero? }
    end

    def acquire_idempotency_lock!(idempotency_key)
      redis = Rails.cache.redis
      key   = idempotency_lock_key(idempotency_key)

      redis.with { |c| c.set(key, 1, nx: true, ex: EVENTABLE_IDEMPOTENCY_TTL) }
    end

    def release_idempotency_lock!(idempotency_key)
      redis = Rails.cache.redis
      key   = idempotency_lock_key(idempotency_key)

      redis.with { |c| !c.del(key).zero? }
    end
  end

  module ClassMethods
    def on_event(event, callback, through: nil, **kwargs)
      callback_key = callback_key_for_event(event)

      define_model_callbacks(callback_key, only: :before) unless
        respond_to?(:"before_#{callback_key}")

      if reflection = reflect_on_association(through)
        raise BadAssociationError, ':through association is too deep (only immediate associations are allowed)' if
          reflection.is_a?(ActiveRecord::Reflection::ThroughReflection)

        raise BadAssociationError, ':through association does not have an inverse association' unless
          reflection.inverse_of.present?

        # Wire up the association to listen for the target event and notify
        # the parent (making the association Eventable if not already)
        klass = reflection.klass
        cb    = -> do
          inverse = send(reflection.inverse_of.name)

          inverse.notify_of_event!(event: event)
        end

        klass.include(Eventable) unless
          klass < Eventable

        klass.on_event(event, cb, **kwargs)
      end

      set_callback(callback_key, :before, callback, **kwargs)
    end

    def on_mutually_exclusive_event(event, callback, raise_on_lock_error: false, wait_on_lock: false, **kwargs)
      # Since we're using :if to acquire our lock below, we're going to
      # append our locking proc to any :if params.
      kwargs.merge!(
        if: Array(kwargs.delete(:if))
              .push(Proc.new {
                acquire_event_lock!(event,
                  raise_on_lock_error: raise_on_lock_error,
                  wait_on_lock: wait_on_lock,
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
                .encode
                .parameterize(separator: '_')
    end
  end
end
