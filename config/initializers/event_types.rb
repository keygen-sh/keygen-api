# frozen_string_literal: true

Rails.configuration.after_initialize do
  ActiveRecord::Base.logger.silence do
    EVENT_TYPES          = EventType.all
    EVENT_TYPES_BY_ID    = EVENT_TYPES.index_by(&:id)
    EVENT_TYPES_BY_EVENT = EVENT_TYPES.index_by(&:event)
  end
end
