# frozen_string_literal: true

class RequestLog < ClickhouseRecord
  self.primary_key = 'id' # for associations

  include Keygen::EE::ProtectedClass[entitlements: %i[request_logs]]
  include Environmental
  include Accountable
  include DateRangeable
  include Limitable
  include Orderable
  include Pageable

  belongs_to :requestor, polymorphic: true, optional: true
  belongs_to :resource,  polymorphic: true, optional: true

  has_environment
  has_account

  # NB(ezekg) this is based on the clickhouse table's ordering key
  scope :ordered, -> (dir = :desc) {
    case dir
    in :desc
      reorder(created_date: :desc).order('UUIDToNum(id) DESC')
    in :asc
      reorder(created_date: :asc).order('UUIDToNum(id) ASC')
    end
  }

  scope :without_blobs, -> {
    select(column_names - %w[request_headers request_body response_headers response_body response_signature])
  }

  scope :search_id, -> (term) {
    id = term.to_s
    return none if
      id.empty?

    return where(id:) if
      UUID_RE.match?(id)

    where('ilike(id::String, ?)', "%#{sanitize_sql_like(id)}%")
  }

  scope :search_requestor, -> *terms {
    case terms
    in [Hash => params]
      search_requestor(params.symbolize_keys.values_at(:type, :id))
    in [[String | Symbol => type, String => id]]
      search_requestor_type(type).search_requestor_id(id)
    in [String | Symbol => type, String => id]
      search_requestor_type(type).search_requestor_id(id)
    in [String => id]
      search_requestor_id(id)
    else
      none
    end
  }

  scope :search_requestor_type, -> (term) {
    requestor_type = term.to_s.underscore.classify
    return none if
      requestor_type.empty?

    where(requestor_type:)
  }

  scope :search_requestor_id, -> (term) {
    requestor_id = term.to_s
    return none if
      requestor_id.empty?

    return where(requestor_id:) if
      UUID_RE.match?(requestor_id)

    where('ilike(requestor_id::String, ?)', "%#{sanitize_sql_like(requestor_id)}%")
  }

  scope :search_resource, -> *terms {
    case terms
    in [Hash => params]
      search_resource(params.symbolize_keys.values_at(:type, :id))
    in [[String | Symbol => type, String => id]]
      search_resource_type(type).search_resource_id(id)
    in [String | Symbol => type, String => id]
      search_resource_type(type).search_resource_id(id)
    in [String => id]
      search_resource_id(id)
    else
      none
    end
  }

  scope :search_resource_type, -> (term) {
    resource_type = term.to_s.underscore.classify
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

    where('ilike(resource_id::String, ?)', "%#{sanitize_sql_like(resource_id)}%")
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

    where('like(url, ?)', "%#{sanitize_sql_like(term)}%")
  }

  scope :search_ip, -> (term) {
    return none if
      term.blank?

    where('ilike(ip, ?)', "#{sanitize_sql_like(term)}%")
  }
end
