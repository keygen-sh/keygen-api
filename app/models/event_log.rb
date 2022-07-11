# frozen_string_literal: true

class EventLog < ApplicationRecord
  include DateRangeable
  include Limitable
  include Orderable
  include Pageable

  belongs_to :account
  belongs_to :event_type
  belongs_to :resource,
    polymorphic: true,
    optional: true
  belongs_to :whodunnit,
    polymorphic: true,
    optional: true
  belongs_to :request_log,
    optional: true

  scope :for_event_type, -> event {
    where(event_type_id: EventType.where(event:))
  }

  scope :search_request_id, -> (term) {
    request_log_id = term.to_s
    return none if
      request_log_id.empty?

    return where(request_log_id:) if
      UUID_RE.match?(request_log_id)

    where('event_logs.request_log_id::text ILIKE ?', "%#{request_log_id}%")
  }

  scope :search_whodunnit, -> (type, id) {
    search_whodunnit_type(type).search_whodunnit_id(id)
  }

  scope :search_whodunnit_type, -> (term) {
    whodunnit_type = term.to_s.underscore.singularize.classify
    return none if
      whodunnit_type.empty?

    where(whodunnit_type:)
  }

  scope :search_whodunnit_id, -> (term) {
    whodunnit_id = term.to_s
    return none if
      whodunnit_id.empty?

    return where(whodunnit_id:) if
      UUID_RE.match?(whodunnit_id)

    where('event_logs.whodunnit_id::text ILIKE ?', "%#{whodunnit_id}%")
  }

  scope :search_resource, -> (type, id) {
    search_resource_type(type).search_resource_id(id)
  }

  scope :search_resource_type, -> (term) {
    resource_type = term.to_s.underscore.singularize.classify
    return none if
      resource_type.empty?

    where(resource_type:)
  }

  scope :search_resource_id, -> (term) {
    resource_id = term.to_s
    return none if
      resource_id.empty?

    return where(resource_id:) if
      UUID_RE.match?(resource_id)

    where('event_logs.resource_id::text ILIKE ?', "%#{resource_id}%")
  }
end
