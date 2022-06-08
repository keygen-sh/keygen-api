# frozen_string_literal: true

class RequestLog < ApplicationRecord
  # FIXME(ezekg) Drop user_agent column after moving to header blobs
  # FIXME(ezekg) Drop these columns after they're moved to blobs
  self.ignored_columns = %w[request_body response_body response_signature]

  include DateRangeable
  include Limitable
  include Orderable
  include Pageable

  belongs_to :account
  belongs_to :requestor, polymorphic: true, optional: true
  belongs_to :resource, polymorphic: true, optional: true
  has_one :event_log,
    inverse_of: :request_log

  has_one :request_body, -> log { where(blob_type: :request_body, account_id: log.account_id) },
    class_name: 'RequestLogBlob',
    inverse_of: :request_log,
    dependent: :delete

  has_one :response_body, -> log { where(blob_type: :response_body, account_id: log.account_id) },
    class_name: 'RequestLogBlob',
    inverse_of: :request_log,
    dependent: :delete

  has_one :response_signature, -> log { where(blob_type: :response_signature, account_id: log.account_id) },
    class_name: 'RequestLogBlob',
    inverse_of: :request_log,
    dependent: :delete

  scope :for_event_type, -> event {
    joins(:event_log).where(
      event_logs: { event_type_id: EventType.where(event:) }
    )
  }

  scope :search_request_id, -> (term) {
    request_id = term.to_s
    return none if
      request_id.empty?

    return where(request_id: request_id) if
      UUID_RE.match?(request_id)

    where('request_logs.request_id::text ILIKE ?', "%#{request_id}%")
  }

  scope :search_requestor, -> (type, id) {
    search_requestor_type(type).search_requestor_id(id)
  }

  scope :search_requestor_type, -> (term) {
    requestor_type = term.to_s.underscore.singularize.classify
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

    where('request_logs.requestor_id::text ILIKE ?', "%#{requestor_id}%")
  }

  scope :search_resource, -> (type, id) {
    search_resource_type(type).search_resource_id(id)
  }

  scope :search_resource_type, -> (term) {
    resource_type = term.to_s.underscore.singularize.classify
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

    where('request_logs.resource_id::text ILIKE ?', "%#{resource_id}%")
  }

  scope :search_method, -> (term) {
    where(method: term.upcase)
  }

  scope :search_status, -> (term) {
    where(status: term.to_s)
  }

  scope :search_url, -> (term) {
    where('request_logs.url LIKE ?', "%#{term}%")
  }

  scope :search_ip, -> (term) {
    where('request_logs.ip ILIKE ?', "%#{term}%")
  }
end
