# frozen_string_literal: true

module Envented
  class BadAssociationError < StandardError; end
  class LockNotAcquiredError < StandardError; end
  class LockTimeoutError < StandardError; end
  class CallbackNotBoundError < StandardError; end

  WILDCARD_SYMBOL    = '*'
  IDEMPOTENCY_PREFIX = 'envented:idem:'
  IDEMPOTENCY_TTL    = 24.hours
  LOCK_PREFIX        = 'envented:lock:'
  LOCK_TTL           = 60.seconds
  LOCK_WAIT_TIMEOUT  = 30.seconds
  LUA_SHASUMS        = {}

  module Callbacks
    extend ActiveSupport::Concern

    included do
      mattr_accessor :__event_callbacks, default: {}

      def notify!(event, idempotency_key: nil)
        callbacks = __event_callbacks.select do |key|
          case
          when key.starts_with?(Envented::WILDCARD_SYMBOL)
            event.ends_with?(key.remove(Envented::WILDCARD_SYMBOL))
          when key.ends_with?(Envented::WILDCARD_SYMBOL)
            event.starts_with?(key.remove(Envented::WILDCARD_SYMBOL))
          else
            event == key
          end
        end

        # Skip if an :idempotency_key was provided and has already been processed
        if idempotency_key.present?
          return unless
            IdempotencyLock.lock(idempotency_key)
        end

        statuses = callbacks.map { |_, c| c.call(self) }
      rescue
        # Release the idempotency lock on complete failure
        IdempotencyLock.unlock(idempotency_key) if
          idempotency_key.present? &&
          statuses&.none?

        raise
      end
    end

    class_methods do
      def on_event(event, callback, **kwargs)
        raise ArgumentError, 'only prefix and suffix wildcards are allowed' if
          !event.starts_with?(Envented::WILDCARD_SYMBOL) &&
          !event.ends_with?(Envented::WILDCARD_SYMBOL) &&
          event.include?('*')

        raise ArgumentError, 'cannot provide more than 1 wildcard' if
          event.count('*') > 1

        # TODO(ezekg) Should each event key accept an array of callbacks?
        __event_callbacks[event] =
          callback.class < Callback ? callback : Callback.new(callback, **kwargs)
      end

      # Guarantees mutual exclusivity of the event. This method ensures that a callback for an event
      # on a record cannot be called concurrently, regardless of how many processess/threads. However,
      # it does not guaranteee that only 1 call can occur. More than one invocation may occur, e.g.
      # after the first lock is released, a second lock is acquired in another thread which was called
      # around the same time as the first (meaning :if/:unless guards returned true). The likelihood
      # of this scenario occurring increases if you use :wait_on_lock.
      #
      # If you're wanting to invoke a given callback at most one time, then special care should be used
      # inside the callback. In addition to using :if/:unless to check if the callback should be called,
      # you should ensure the callback is idempotent, i.e. it can called more than once without
      # consequences. There is no guarantee the callback will be called only once.
      #
      # The locking algorithm used is Redlock (https://redis.io/topics/distlock).
      #
      def on_exclusive_event(event, callback, **kwargs)
        exclusive_callback = ExclusiveCallback.new(callback, on: event, **kwargs)

        on_event(event, exclusive_callback, **kwargs)
      end
    end
  end

  class Callback
    def initialize(callback, if: nil, unless: nil)
      @callback = CallbackMethod.build(callback)

      unless_value = binding.local_variable_get(:unless)
      if_value     = binding.local_variable_get(:if)

      raise ArgumentError, 'cannot provide both :if and :unless' if
        unless_value.present? &&
        if_value.present?

      @guard =
        case
        when unless_value.present?
          CallbackMethod.build(unless_value, invert: true)
        when if_value.present?
          CallbackMethod.build(if_value)
        end
    end

    def call(ctx)
      return false if
        @guard.present? && !@guard.call(ctx)

      @callback.call(ctx)
    end
  end

  class ExclusiveCallback < Callback
    def initialize(callback, on:, lock_id_method: :id, raise_on_lock_error: false, wait_on_lock: false, lock_wait_timeout: Envented::LOCK_WAIT_TIMEOUT, auto_release_lock: true, **kwargs)
      super(callback, **kwargs)

      @on                  = on
      @lock_id_method      = lock_id_method
      @raise_on_lock_error = raise_on_lock_error
      @wait_on_lock        = wait_on_lock
      @lock_wait_timeout   = lock_wait_timeout
      @auto_release_lock   = auto_release_lock
    end

    def call(ctx)
      lock_id = [ctx.send(@lock_id_method), @on].join(':')
      token   = RedLock.lock!(lock_id,
        raise_on_lock_error: @raise_on_lock_error,
        wait_on_lock: @wait_on_lock,
        lock_wait_timeout: @lock_wait_timeout,
      )

      return false if
        token.nil?

      super(ctx)
    ensure
      RedLock.unlock!(lock_id, token: token) if
        @auto_release_lock &&
        lock_id.present? &&
        token.present?
    end
  end

  class CallbackMethod
    def self.build(method, invert: false)
      case method
      when Symbol
        SymbolMethod.new(method, invert: invert)
      when Proc
        ProcMethod.new(method, invert: invert)
      else
        raise ArgumentError, 'must be a symbol or proc'
      end
    end
  end

  class SymbolMethod
    def initialize(method, invert: false)
      raise ArgumentError, 'method must be a symbol' unless
        method.is_a?(Symbol)

      @invert = invert
      @method = method
    end

    def call(ctx)
      ok = ctx.send(@method)
      return !ok if
        inverted?

      ok
    end

    private

    def inverted?
      @invert
    end
  end

  class ProcMethod
    def initialize(method, invert: false)
      raise ArgumentError, 'method must be a proc' unless
        method.is_a?(Proc)

      @invert = invert
      @method = method
    end

    def call(ctx)
      ok = ctx.instance_exec(&@method)
      return !ok if
        inverted?

      ok
    end

    private

    def inverted?
      @invert
    end
  end

  class IdempotencyLock
    def self.lock!(key)
      redis { it.set(Envented::IDEMPOTENCY_PREFIX + key, 1, nx: true, ex: Envented::IDEMPOTENCY_TTL) }
    end

    def self.lock(...)
      lock!(...)
    rescue => e
      Keygen.logger.warn(e)

      false
    end

    def self.unlock!(key)
      redis { !it.del(Envented::IDEMPOTENCY_PREFIX + key).zero? }
    end

    def self.unlock(...)
      unlock!(...)
    rescue => e
      Keygen.logger.warn(e)

      false
    end

    private

    def self.redis(&block)
      Rails.cache.redis.with { |c| yield c }
    end
  end

  # See: https://redis.io/topics/distlock
  class RedLock
    def self.lock!(id, raise_on_lock_error:, wait_on_lock:, lock_wait_timeout:)
      key   = Envented::LOCK_PREFIX + id
      token = nil

      Timeout.timeout(lock_wait_timeout) do
        loop do
          token = SecureRandom.hex
          if redis { it.set(key, token, nx: true, ex: Envented::LOCK_TTL) }
            return token
          end

          if raise_on_lock_error
            raise LockNotAcquiredError, 'failed to acquire lock' unless
              wait_on_lock
          end

          return nil unless
            wait_on_lock

          sleep rand(0.1..1.0)
        end
      end
    rescue Timeout::Error
      # Always attempt to release the lock for the current token on error,
      # since Timeout could, although unlikely, raise after we obtain a lock
      # but before we exit the method. This ensures the lock is released.
      unlock!(id, token: token) unless
        token.nil?

      raise LockTimeoutError, 'lock timeout' if
        raise_on_lock_error
    end

    def self.unlock!(id, token:)
      key = Envented::LOCK_PREFIX + id
      cmd = <<~LUA
        if redis.call('get', KEYS[1]) == ARGV[1] then
          return redis.call('del', KEYS[1])
        else
          return 0
        end
      LUA

      shasum = (Envented::LUA_SHASUMS[:unlock] ||= Digest::SHA1.hexdigest(cmd))
      res    = begin
                 redis { it.evalsha(shasum, keys: [key], argv: [token]) }
               rescue Redis::CommandError
                 redis { it.eval(cmd, keys: [key], argv: [token]) }
               end

      !res.zero?
    end

    private

    def self.redis(&block)
      Rails.cache.redis.with { |c| yield c }
    end
  end
end
