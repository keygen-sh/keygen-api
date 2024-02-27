# frozen_string_literal: true

module Keygen
  class Logger
    def self.exception(e, context: nil)
      Rails.logger.error(context) if context.present?
      Rails.logger.error(e.message)
      Rails.logger.error(e.backtrace&.join("\n"))
      Sentry.capture_exception(e)
    end

    def self.error(msg = nil, &block)
      if block_given?
        Rails.logger.error(&block)
      else
        Rails.logger.error(msg)
      end
    end

    def self.warn(msg = nil, &block)
      if block_given?
        Rails.logger.warn(&block)
      else
        Rails.logger.warn(msg)
      end
    end

    def self.info(msg = nil, &block)
      if block_given?
        Rails.logger.info(&block)
      else
        Rails.logger.info(msg)
      end
    end

    def self.debug(msg = nil, &block)
      if block_given?
        Rails.logger.debug(&block)
      else
        Rails.logger.debug(msg)
      end
    end
  end
end
