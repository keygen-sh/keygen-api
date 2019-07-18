# frozen_string_literal: true

module Billings
  class RetrieveEventService < BaseService

    def initialize(event:)
      @event = event
    end

    def execute
      Billings::BaseService::Event.retrieve event
    rescue Billings::BaseService::Error
      nil
    end

    private

    attr_reader :event
  end
end
