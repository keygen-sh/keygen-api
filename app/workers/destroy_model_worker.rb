class DestroyModelWorker
  include Sidekiq::Worker

  sidekiq_options queue: :deletes

  def perform(type, id)
    klass = "#{type}".classify.constantize
    model = klass.find id

    model.destroy!
  end
end
