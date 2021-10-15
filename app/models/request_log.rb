# frozen_string_literal: true

class RequestLog < ApplicationRecord
  include DateRangeable
  include Limitable
  include Pageable
  include Searchable

  SEARCH_ATTRIBUTES = [:request_id, :requestor_type, :requestor_id, :resource_type, :resource_id, :status, :method, :url, :ip].freeze
  SEARCH_RELATIONSHIPS = {}.freeze

  belongs_to :account
  belongs_to :requestor, polymorphic: true
  belongs_to :resource, polymorphic: true

  validates :account, presence: { message: "must exist" }

  # NOTE(ezekg) A lot of the time, we don't need to load the request
  #             or response body, e.g. when listing logs.
  scope :without_blobs, -> {
    select(self.attribute_names - %w[request_body response_body response_signature])
  }

  scope :for_current_period, -> {
    date_start = 2.weeks.ago.beginning_of_day
    date_end = Time.current

    where created_at: (date_start..date_end)
  }

  # FIXME(ezekg) Rip out pg_search for other models and replace with scopes
  scope :search_request_id, -> (term) {
    request_id = term.to_s
    return none if
      request_id.empty?

    return where(request_id: request_id) if
      UUID_REGEX.match?(request_id)

    where('request_id::text ILIKE ?', "%#{request_id}%")
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
      UUID_REGEX.match?(requestor_id)

    where('requestor_id::text ILIKE ?', "%#{requestor_id}%")
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
      UUID_REGEX.match?(resource_id)

    where('resource_id::text ILIKE ?', "%#{resource_id}%")
  }

  scope :search_method, -> (term) {
    where(method: term.upcase)
  }

  scope :search_status, -> (term) {
    where(status: term.to_s)
  }

  scope :search_url, -> (term) {
    where('url LIKE ?', "%#{term}%")
  }

  scope :search_ip, -> (term) {
    where('ip ILIKE ?', "%#{term}%")
  }
end
