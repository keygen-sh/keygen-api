TEST_ENV = "test".freeze

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  default_scope -> {
    # FIXME(ezekg) It's easier to test things when sort order to ASC
    case Rails.env
    when TEST_ENV
      order created_at: :asc
    else
      order created_at: :desc
    end
  }

  def destroy_async
    DestroyModelWorker.perform_async self.class.name, self.id
  end
end
