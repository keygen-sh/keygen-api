class SerializableRole < SerializableBase
  type :roles

  attribute :name
  attribute :created do
    @object.created_at
  end
  attribute :updated do
    @object.updated_at
  end

  relationship :account do
    link :related do
      @url_helpers.v1_account_path @object.resource.account
    end
  end
  relationship :resource do
    link :related do
      @url_helpers.send "v1_account_#{@object.resource.class.name.demodulize.underscore}_path",
                        @object.resource.account, @object.resource
    end
  end

  link :self do
    @url_helpers.send "v1_account_#{@object.resource.class.name.demodulize.underscore}_role_path",
                      @object.resource.account, @object.resource
  end
end
