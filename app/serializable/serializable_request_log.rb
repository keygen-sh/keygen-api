# frozen_string_literal: true

class SerializableRequestLog < SerializableBase
  type "request-logs"

  attribute :request_id
  attribute :url
  attribute :method
  attribute :status
  attribute :user_agent
  attribute :ip
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

  link :self do
    @url_helpers.v1_account_request_log_path @object.account_id, @object
  end
end
