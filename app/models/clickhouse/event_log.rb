# frozen_string_literal: true

class EventLog < ClickhouseRecord
  self.primary_key = 'id' # for associations

  include Keygen::EE::ProtectedClass[entitlements: %i[event_logs]]
  include Environmental
  include Accountable
  include DateRangeable
  include Limitable
  include Orderable
  include Pageable

  keyset_pagination do |scope, cursor:, size:, order:|
    if cursor.present?
      comparator = order == :desc ? '<' : '>'

      # NB(ezekg) clickhouse raises if the keyset tuple is empty, i.e. the cursor
      #           row doesn't exist, so we're joining on a CTE beforehand.
      cursor_cte = scope.reselect(:created_date, :id)
                        .where(id: cursor)
                        .ordered(order)
                        .limit(1)

      scope = scope.with(cursor: cursor_cte)
                   .joins('JOIN cursor ON TRUE')
                   .where(
                     "(#{table_name}.created_date, UUIDToNum(#{table_name}.id)) #{comparator} (cursor.created_date, UUIDToNum(cursor.id))",
                   )
    end

    scope.ordered(order)
         .limit(size)
  end

  belongs_to :event_type
  belongs_to :resource,    polymorphic: true, optional: true
  belongs_to :whodunnit,   polymorphic: true, optional: true
  belongs_to :request_log,                    optional: true

  has_environment
  has_account

  validates :metadata,
    json: {
      maximum_bytesize: 16.kilobytes,
      maximum_depth: 4,
      maximum_keys: 64,
    }

  # NB(ezekg) this is based on the clickhouse table's ordering key
  scope :ordered, -> (dir = :desc) {
    case dir
    in :desc
      reorder(created_date: :desc).order('UUIDToNum(id) DESC')
    in :asc
      reorder(created_date: :asc).order('UUIDToNum(id) ASC')
    end
  }

  scope :for_event_types, -> events {
    event_type_ids = EventType.where(event: events)
                              .ids

    where(event_type_id: event_type_ids)
  }

  scope :for_event_type, -> event {
    for_event_types(event)
  }

  scope :search_request_id, -> (term) {
    request_log_id = term.to_s
    return none if
      request_log_id.empty?

    return where(request_log_id:) if
      UUID_RE.match?(request_log_id)

    where('ilike(request_log_id::String, ?)', "%#{sanitize_sql_like(request_log_id)}%")
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
  }

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

    where('ilike(whodunnit_id::String, ?)', "%#{sanitize_sql_like(whodunnit_id)}%")
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
end
