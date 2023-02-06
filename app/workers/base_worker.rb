# frozen_string_literal: true

class BaseWorker
  include Sidekiq::Worker

  sidekiq_options cronitor_disabled: true
end
