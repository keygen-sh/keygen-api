class DestroyModelWorker
  include Sidekiq::Worker

  sidekiq_options queue: :deletes

  def perform(type, id)
    klass = "#{type}".classify.constantize
    model = klass.find_by! id: id

    model.destroy!
  end
end
