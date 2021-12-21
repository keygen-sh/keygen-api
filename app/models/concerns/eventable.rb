# frozen_string_literal: true

# TODO(ezekg) Extract out to an `eventor` gem?
module Eventable
  extend ActiveSupport::Concern

  EVENTABLE_WILDCARD_SENTINEL = SecureRandom.hex(4)
  EVENTABLE_CALLBACK_PREFIX   = '__eventable_'
  EVENTABLE_REDIS_PREFIX      = 'eventable:'
  EVENTABLE_REDIS_TTL         = 1.year.to_i

  included do
    extend ActiveModel::Callbacks

    def notify!(event:)
      key     = self.class.to_eventable_key(event)
      matches = matching_callbacks(key)

      matches.map { |k| run_callbacks(k) }
    end

    private

    def matching_callbacks(key)
      callbacks = __callbacks.select do |k, v|
        case
        when k.starts_with?(EVENTABLE_CALLBACK_PREFIX + EVENTABLE_WILDCARD_SENTINEL)
          suffix = k.to_s.remove(EVENTABLE_CALLBACK_PREFIX + EVENTABLE_WILDCARD_SENTINEL)

          key.ends_with?(suffix)
        when k.ends_with?(EVENTABLE_WILDCARD_SENTINEL)
          prefix = k.to_s.remove(EVENTABLE_WILDCARD_SENTINEL)

          key.starts_with?(prefix)
        else
          key == k
        end
      end

      callbacks.keys
    end
  end

  module ClassMethods
    def after_event(event, callback, **kwargs)
      key = to_eventable_key(event)

      define_model_callbacks(key, only: :after) unless
        model_callbacks_defined?(key)

      if reflection = reflect_on_association(kwargs.delete(:through))
        klass = reflection.klass
        cb    = -> do
          inverse = send(reflection.inverse_of.name)

          inverse.notify!(event: event)
        end

        klass.include(Eventable) unless
          klass < Eventable

        klass.after_event(event, cb, **kwargs)
      end

      set_callback(key, :after, callback, **kwargs)
    end
    alias_method :on_event, :after_event

    def after_first_event(event, callback, **kwargs)
      kwargs = kwargs.merge if: -> {
        redis = Rails.cache.redis
        key   = EVENTABLE_REDIS_PREFIX + Digest::SHA2.hexdigest("#{id}:#{event}")
        nonce = Time.current.to_i

        redis.with do |conn|
          conn.set(key, nonce, nx: true, px: EVENTABLE_REDIS_TTL)
        end
      }

      after_event(event, callback, **kwargs)
    end
    alias_method :on_first_event, :after_first_event

    def to_eventable_key(event)
      key = EVENTABLE_CALLBACK_PREFIX +
        event.to_s.sub('*', EVENTABLE_WILDCARD_SENTINEL)
                  .underscore
                  .parameterize(separator: '_')

      key.to_sym
    end

    private

    def model_callbacks_defined?(key)
      respond_to?(:"after_#{key}")
    end
  end
end
