# frozen_string_literal: true

class EventLogSerializer < BaseSerializer
  type 'event-logs'

  attribute :event do
    @object.event_type.event
  end
  attribute :metadata do
    @object.metadata&.deep_transform_keys { it.to_s.camelize :lower } or {}
  end
  attribute :created do
    @object.created_at
  end
  attribute :updated do
    @object.updated_at
  end

  relationship :account do
    linkage always: true do
      { type: :accounts, id: @object.account_id }
    end
    link :related do
      @url_helpers.v1_account_path @object.account_id
    end
  end

  ee do
    relationship :environment do
      linkage always: true do
        if @object.environment_id.present?
          { type: :environments, id: @object.environment_id }
        else
          nil
        end
      end
      link :related do
        if @object.environment_id.present?
          @url_helpers.v1_account_environment_path @object.account_id, @object.environment_id
        else
          nil
        end
      end
    end
  end

  relationship :request do
    linkage always: true do
      next if
        @object.request_log_id.nil?

      { type: 'request-logs', id: @object.request_log_id }
    end

    if @object.request_log_id.present?
      link :related do
        @url_helpers.v1_account_request_log_path @object.account_id, @object.request_log_id
      end
    end
  end

  relationship :whodunnit do
    linkage always: true do
      Keygen::JSONAPI.linkage_for(@object.whodunnit_type, @object.whodunnit_id)
    end

    if @object.whodunnit_type? && @object.whodunnit_id?
      link :related do
        Keygen.routing.path_for(@object.whodunnit_type, id: @object.whodunnit_id, account: @object.account)
      end
    end
  end

  relationship :resource do
    linkage always: true do
      Keygen::JSONAPI.linkage_for(@object.resource_type, @object.resource_id)
    end

    if @object.resource_type? && @object.resource_id?
      link :related do
        Keygen.routing.path_for(@object.resource_type, id: @object.resource_id, account: @object.account)
      end
    end
  end

  link :self do
    @url_helpers.v1_account_event_log_path @object.account_id, @object
  end
end
