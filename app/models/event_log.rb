# frozen_string_literal: true

class EventLog < ApplicationRecord
  include Keygen::EE::ProtectedClass[entitlements: %i[event_logs]]
  include Keygen::PortableClass
  include Environmental
  include Accountable
  include DateRangeable
  include Limitable
  include Orderable
  include Pageable

  belongs_to :event_type
  belongs_to :resource,
    polymorphic: true,
    optional: true
  belongs_to :whodunnit,
    polymorphic: true,
    optional: true
  belongs_to :request_log,
    optional: true

  has_environment
  has_account

  # map event type primary keys between installs
  exports -> attrs { attrs.merge(event_type_event: EventType.lookup_event_by_id(attrs.delete(:event_type_id))) }
  imports -> attrs { attrs.merge(event_type_id: EventType.lookup_id_by_event(attrs.delete(:event_type_event))) }

  # NOTE(ezekg) Would love to add a default instead of this, but alas,
  #             the table is too big and it would break everything.
  before_create -> { self.created_date ||= (created_at || Date.current) }

  scope :for_event_type, -> event {
    where(event_type_id: EventType.where(event:))
  }

  scope :search_request_id, -> (term) {
    request_log_id = term.to_s
    return none if
      request_log_id.empty?

    return where(request_log_id:) if
      UUID_RE.match?(request_log_id)

    where('event_logs.request_log_id::text ILIKE ?', "%#{sanitize_sql_like(request_log_id)}%")
  }

  scope :search_whodunnit, -> *terms {
    case terms
    in [Hash => params]
      search_whodunnit(params.symbolize_keys.values_at(:type, :id))
    in [[String | Symbol => type, String => id]]
      search_whodunnit_type(type).search_whodunnit_id(id)
    in [String | Symbol => type, String => id]
      search_whodunnit_type(type).search_whodunnit_id(id)
    in [String => id]
      search_whodunnit_id(id)
    else
      none
    end
  } do
    def environments = search_whodunnit_type(:environment)
    def products     = search_whodunnit_type(:product)
    def licenses     = search_whodunnit_type(:license)
    def users        = search_whodunnit_type(:user)
  end

  scope :search_whodunnit_type, -> (term) {
    whodunnit_type = term.to_s.underscore.classify
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

    where('event_logs.whodunnit_id::text ILIKE ?', "%#{sanitize_sql_like(whodunnit_id)}%")
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
  } do
    def environments = search_resource_type(:environment)
    def products     = search_resource_type(:product)
    def licenses     = search_resource_type(:license)
    def users        = search_resource_type(:user)
  end

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

    where('event_logs.resource_id::text ILIKE ?', "%#{sanitize_sql_like(resource_id)}%")
  }
end
