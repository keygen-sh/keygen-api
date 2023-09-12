# frozen_string_literal: true

class RequestLog < ApplicationRecord
  include Keygen::EE::ProtectedClass[entitlements: %i[request_logs]]
  include Environmental
  include DateRangeable
  include Limitable
  include Orderable
  include Pageable

  belongs_to :account
  belongs_to :requestor, polymorphic: true, optional: true
  belongs_to :resource, polymorphic: true, optional: true
  has_one :event_log,
    inverse_of: :request_log

  has_environment

  # NOTE(ezekg) Would love to add a default instead of this, but alas,
  #             the table is too big and it would break everything.
  before_create -> { self.created_date ||= (created_at || Date.current) }

  # NOTE(ezekg) A lot of the time, we don't need to load the request
  #             or response body, e.g. when listing logs.
  scope :without_blobs, -> {
    select(self.attribute_names - %w[request_headers request_body response_headers response_body response_signature])
  }

  scope :yesterday, -> { where(created_at: Date.yesterday.all_day) }
  scope :today,     -> { where(created_at: Date.today.all_day) }

  scope :for_current_period, -> {
    date_start = 2.weeks.ago.beginning_of_day
    date_end   = Time.current

    where(created_at: date_start..date_end)
  }

  scope :for_event_type, -> event {
    joins(:event_log).where(
      event_logs: { event_type_id: EventType.where(event:) }
    )
  }

  scope :search_id, -> (term) {
    id = term.to_s
    return none if
      id.empty?

    return where(id:) if
      UUID_RE.match?(id)

    where('request_logs.id::text ILIKE ?', "%#{sanitize_sql_like(id)}%")
  }

  scope :search_requestor, -> (type, id) {
    search_requestor_type(type).search_requestor_id(id)
  }

  scope :search_requestor_type, -> (term) {
    requestor_type = term.to_s.underscore.classify
    return none if
      requestor_type.empty?

    where(requestor_type: requestor_type)
  }

  scope :search_requestor_id, -> (term) {
    requestor_id = term.to_s
    return none if
      requestor_id.empty?

    return where(requestor_id: requestor_id) if
      UUID_RE.match?(requestor_id)

    where('request_logs.requestor_id::text ILIKE ?', "%#{sanitize_sql_like(requestor_id)}%")
  }

  scope :search_resource, -> (type, id) {
    search_resource_type(type).search_resource_id(id)
  }

  scope :search_resource_type, -> (term) {
    resource_type = term.to_s.underscore.classify
    return none if
      resource_type.empty?

    where(resource_type: resource_type)
  }

  scope :search_resource_id, -> (term) {
    resource_id = term.to_s
    return none if
      resource_id.empty?

    return where(resource_id: resource_id) if
      UUID_RE.match?(resource_id)

    where('request_logs.resource_id::text ILIKE ?', "%#{sanitize_sql_like(resource_id)}%")
  }

  scope :search_method, -> (term) {
    where(method: term.upcase)
  }

  scope :search_status, -> (term) {
    where(status: term.to_s)
  }

  scope :search_url, -> (term) {
    return none if
      term.blank?

    where('request_logs.url LIKE ?', "%#{sanitize_sql_like(term)}%")
  }

  scope :search_ip, -> (term) {
    return none if
      term.blank?

    where('request_logs.ip ILIKE ?', "#{sanitize_sql_like(term)}%")
  }
end
