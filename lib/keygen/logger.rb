module Keygen
  class Logger
    def self.exception(e, context: nil)
      Rails.logger.error context if context.present?
      Rails.logger.error e.message
      Rails.logger.error e.backtrace.join("\n")
    end

    def self.error(msg)
      Rails.logger.error msg
    end

    def self.warn(msg)
      Rails.logger.warn msg
    end

    def self.info(msg)
      Rails.logger.info msg
    end

    def self.debug(msg)
      Rails.logger.debug msg
    end
  end

  def self.logger
    Logger
  end
end