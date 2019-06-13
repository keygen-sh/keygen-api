class SerializableMachine < SerializableBase
  type :machines

  attribute :fingerprint
  attribute :ip
  attribute :hostname
  attribute :platform
  attribute :name
  attribute :require_heartbeat do
    @object.requires_heartbeat?
  end
  attribute :heartbeat_status
  attribute :last_heartbeat do
    @object.last_heartbeat_at
  end
  attribute :next_heartbeat do
    @object.next_heartbeat_at
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
    linkage always: true do
      { type: :accounts, id: @object.account_id }
    end
    link :related do
      @url_helpers.v1_account_path @object.account_id
    end
  end
  relationship :product do
    linkage always: true do
      { type: :products, id: @object.product&.id }
    end
    link :related do
      @url_helpers.v1_account_machine_product_path @object.account_id, @object
    end
  end
  relationship :license do
    linkage always: true do
      { type: :licenses, id: @object.license_id }
    end
    link :related do
      @url_helpers.v1_account_machine_license_path @object.account_id, @object
    end
  end
  relationship :user do
    linkage always: true do
      if @object.license.user_id.present?
        { type: :users, id: @object.license.user_id }
      else
        nil
      end
    end
    link :related do
      @url_helpers.v1_account_machine_user_path @object.account_id, @object
    end
  end

  link :self do
    @url_helpers.v1_account_machine_path @object.account_id, @object
  end
end
