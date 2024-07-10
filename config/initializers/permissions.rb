# frozen_string_literal: true

Rails.configuration.after_initialize do
  ActiveRecord::Base.logger.silence do
    PERMISSIONS           = Permission.all
    PERMISSIONS_BY_ID     = PERMISSIONS.index_by(&:id)
    PERMISSIONS_BY_ACTION = PERMISSIONS.index_by(&:action)
  end
end
