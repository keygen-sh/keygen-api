# frozen_string_literal: true

Rails.configuration.to_prepare do
  ActiveRecord::Base.logger.silence do
    PERMISSIONS           = Permission.all
    PERMISSIONS_BY_ID     = PERMISSIONS.index_by(&:id)
    PERMISSIONS_BY_ACTION = PERMISSIONS.index_by(&:action)
  rescue ActiveRecord::NoDatabaseError
    # database may not be created yet, so we swallow this to allow
    # it to be created, e.g. during test setup.
  end
end
