class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  default_scope -> { order "created_at ASC" }

  def destroy_async
    DestroyModelWorker.perform_async self.class.name, self.id
  end
end
