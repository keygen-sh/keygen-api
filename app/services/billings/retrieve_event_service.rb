# frozen_string_literal: true

module Billings
  class RetrieveEventService < BaseService

    def initialize(event:)
      @event = event
    end

    def execute
      Billings::Event.retrieve(event)
    rescue Billings::Error => e
      Keygen.logger.exception(e)

      nil
    end

    private

    attr_reader :event
  end
end
