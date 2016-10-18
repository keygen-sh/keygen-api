module Billings
  class RetrieveEventService < BaseService

    def initialize(id:)
      @id = id
    end

    def execute
      ::Billings::BaseService::Event.retrieve id
    rescue ::Billings::BaseService::Error
      nil
    end

    private

    attr_reader :id
  end
end
