class SerializableToken < SerializableBase
  type :tokens

  attribute :kind
  attribute :token, if: -> { @object.raw.present? } do
    @object.raw
  end
  attribute :expiry
  attribute :max_activations, if: -> { @object.activation_token? }
  attribute :activations, if: -> { @object.activation_token? }
  attribute :max_deactivations, if: -> { @object.activation_token? }
  attribute :deactivations, if: -> { @object.activation_token? }
  attribute :created do
    @object.created_at
  end
  attribute :updated do
    @object.updated_at
  end

  relationship :account do
    linkage always: true
    link :related do
      @url_helpers.v1_account_path @object.account
    end
  end
  relationship :bearer do
    linkage always: true
    link :related do
      @url_helpers.send "v1_account_#{@object.bearer.class.name.demodulize.underscore}_path",
                        @object.account, @object.bearer
    end
  end

  link :self do
    @url_helpers.v1_account_token_path @object.account, @object
  end
end
