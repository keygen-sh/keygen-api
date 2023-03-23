# frozen_string_literal: true

class RequestLogSerializer < BaseSerializer
  type 'request-logs'

  attribute :url
  attribute :method
  attribute :status
  attribute :user_agent
  attribute :ip
  attribute :request_body do
    if @object.respond_to?(:request_body)
      @object.request_body
    else
      '[REDACTED]'
    end
  end
  attribute :response_signature do
    if @object.respond_to?(:response_signature)
      @object.response_signature
    else
      '[REDACTED]'
    end
  end
  attribute :response_body do
    if @object.respond_to?(:response_body)
      @object.response_body
    else
      '[REDACTED]'
    end
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
        unless @object.environment_id.nil?
          @url_helpers.v1_account_environment_path @object.account_id, @object.environment_id
        end
      end
    end
  end

  relationship :requestor do
    linkage always: true do
      next if @object.requestor_id.nil? || @object.requestor_type.nil?

      t = @object.requestor_type.underscore.pluralize.parameterize

      { type: t, id: @object.requestor_id }
    end

    if @object.requestor_id.present? && @object.requestor_type.present?
      link :related do
        @url_helpers.send "v1_account_#{@object.requestor_type.underscore}_path", @object.account_id, @object.requestor_id
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
        t = "#{@object.resource_type}Serializer".safe_constantize
                                                .type_val

        @url_helpers.send "v1_account_#{t}_path", @object.account_id, @object.resource_id
      end
    end
  end

  link :self do
    @url_helpers.v1_account_request_log_path @object.account_id, @object
  end
end
