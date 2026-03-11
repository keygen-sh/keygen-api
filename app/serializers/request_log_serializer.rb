# frozen_string_literal: true

class RequestLogSerializer < BaseSerializer
  type 'request-logs'

  attribute :url
  attribute :method
  attribute :status
  attribute :user_agent
  attribute :ip
  attribute :request_headers do
    if @object.respond_to?(:request_headers)
      @object.request_headers || {}
    else
      nil
    end
  end
  attribute :request_body do
    if @object.respond_to?(:request_body)
      @object.request_body
    else
      nil
    end
  end
  attribute :response_signature do
    if @object.respond_to?(:response_signature)
      @object.response_signature
    else
      nil
    end
  end
  attribute :response_headers do
    if @object.respond_to?(:response_headers)
      @object.response_headers || {}
    else
      nil
    end
  end
  attribute :response_body do
    if @object.respond_to?(:response_body)
      @object.response_body
    else
      nil
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
        if @object.environment_id.present?
          @url_helpers.v1_account_environment_path @object.account_id, @object.environment_id
        else
          nil
        end
      end
    end
  end

  relationship :requestor do
    linkage always: true do
      Keygen::JSONAPI.linkage_for(@object.requestor_type, @object.requestor_id)
    end

    if @object.requestor_type? &&@object.requestor_id?
      link :related do
        Keygen.routing.path_for(@object.requestor_type, id: @object.requestor_id, account: @object.account)
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
    @url_helpers.v1_account_request_log_path @object.account_id, @object
  end
end
