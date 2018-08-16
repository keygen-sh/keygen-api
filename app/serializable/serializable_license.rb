class SerializableLicense < SerializableBase
  type :licenses

  attribute :key, unless: -> { @object.policy.encrypted? && @object.raw.nil? } do
    if @object.policy.encrypted?
      @object.raw
    else
      @object.key
    end
  end
  attribute :expiry
  attribute :uses
  attribute :suspended
  attribute :encrypted do
    @object.policy.encrypted?
  end
  attribute :strict do
    @object.policy.strict?
  end
  attribute :floating do
    @object.policy.floating?
  end
  attribute :concurrent do
    @object.policy.concurrent?
  end
  attribute :protected do
    @object.protected?
  end
  attribute :max_machines do
    @object.policy.max_machines
  end
  attribute :max_uses do
    @object.policy.max_uses
  end
  attribute :require_check_in do
    @object.policy.require_check_in
  end
  attribute :last_check_in do
    @object.last_check_in_at
  end
  attribute :next_check_in do
    @object.next_check_in_at
  end
  attribute :metadata do
    @object.metadata&.transform_keys { |k| k.to_s.camelize :lower } or {}
  end
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
  relationship :product do
    linkage always: true
    link :related do
      @url_helpers.v1_account_license_product_path @object.account, @object
    end
  end
  relationship :policy do
    linkage always: true
    link :related do
      @url_helpers.v1_account_license_policy_path @object.account, @object
    end
  end
  relationship :user do
    linkage always: true
    link :related do
      @url_helpers.v1_account_license_user_path @object.account, @object
    end
  end
  relationship :machines do
    link :related do
      @url_helpers.v1_account_license_machines_path @object.account, @object
    end
    meta do
      { count: @object.machines.count }
    end
  end
  relationship :tokens do
    link :related do
      @url_helpers.v1_account_license_tokens_path @object.account, @object
    end
  end

  link :self do
    @url_helpers.v1_account_license_path @object.account, @object
  end
end
