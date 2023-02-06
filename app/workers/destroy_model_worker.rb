# frozen_string_literal: true

class DestroyModelWorker < BaseWorker
  sidekiq_options queue: :critical

  def perform(type, id)
    klass = "#{type}".classify.constantize
    model = klass.find_by! id: id

    model.destroy!
  rescue ActiveRecord::RecordNotFound
    # NOTE(ezekg) Already destroyed
  end
end
