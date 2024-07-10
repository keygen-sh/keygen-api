# frozen_string_literal: true

Rails.configuration.to_prepare do
  ActiveRecord::Base.logger.silence do
    EVENT_TYPES          = EventType.all
    EVENT_TYPES_BY_ID    = EVENT_TYPES.index_by(&:id)
    EVENT_TYPES_BY_EVENT = EVENT_TYPES.index_by(&:event)
  rescue ActiveRecord::NoDatabaseError
    # database may not be created yet, so we swallow this to allow
    # it to be created, e.g. during test setup.
  end
end
