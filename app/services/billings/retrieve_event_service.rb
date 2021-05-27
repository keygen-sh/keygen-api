# frozen_string_literal: true

module Billings
  class RetrieveEventService < BaseService

    def initialize(event:)
      @event = event
    end

    def execute
      Billings::Event.retrieve(event)
    rescue Billings::Error
      nil
    end

    private

    attr_reader :event
  end
end
