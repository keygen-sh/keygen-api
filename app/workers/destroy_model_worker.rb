# frozen_string_literal: true

class DestroyModelWorker
  include Sidekiq::Worker

  sidekiq_options queue: :deletes

  def perform(type, id)
    klass = "#{type}".classify.constantize
    model = klass.find_by! id: id

    model.destroy!
  rescue ActiveRecord::RecordNotFound
    # NOTE(ezekg) Already destroyed
  end
end
