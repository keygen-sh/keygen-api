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
  relationship :token do
    linkage always: true do
      if @object.token_id.present?
        { type: :tokens, id: @object.token_id }
      else
        nil
      end
    end
    link :related do
      if @object.token_id.present?
        @url_helpers.v1_account_token_path @object.account_id, @object.token_id
      else
        nil
      end
    end
  end
  relationship :requestor do
    linkage always: true do
      if @object.requestor_id.present?
        { type: @object.requestor_type.underscore.pluralize, id: @object.requestor_id }
      else
        nil
      end
    end
    link :related do
      if @object.requestor_id.present?
        @url_helpers.send "v1_account_#{@object.requestor_type.underscore}_path",
                          @object.account_id, @object.requestor_id
      else
        nil
      end
    end
  end

  link :self do
    @url_helpers.v1_account_request_log_path @object.account_id, @object
  end
end
