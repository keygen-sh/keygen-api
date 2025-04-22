# frozen_string_literal: true

class EventLogSerializer < BaseSerializer
  type 'event-logs'

  attribute :event do
    @object.event_type.event
  end
  attribute :metadata do
    @object.metadata&.deep_transform_keys { _1.to_s.camelize :lower } or {}
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
      next if
        @object.whodunnit_id.nil? || @object.whodunnit_type.nil?

      t = @object.whodunnit_type.underscore.pluralize.parameterize

      { type: t, id: @object.whodunnit_id }
    end

    if @object.whodunnit_id.present? && @object.whodunnit_type.present?
      link :related do
        @url_helpers.polymorphic_path [:v1, @object.account, @object.whodunnit]
      end
    end
  end

  relationship :resource do
    linkage always: true do
      next if @object.resource_id.nil? || @object.resource_type.nil?

      # FIXME(ezekg) This is a probably not a great idea but we need to support
      #              models where the type does not match the model name, e.g.
      #              artifacts and platforms.
      t = "#{@object.resource_type}Serializer".safe_constantize
                                              .type_val

      { type: t, id: @object.resource_id }
    end

    if @object.resource_id.present? && @object.resource_type.present?
      link :related do
        if @object.resource in Accountable # event subject could be e.g. the account
          @url_helpers.polymorphic_path [:v1, @object.account, @object.resource]
        else
          @url_helpers.polymorphic_path [:v1, @object.resource]
        end
      end
    end
  end

  link :self do
    @url_helpers.v1_account_event_log_path @object.account_id, @object
  end
end
