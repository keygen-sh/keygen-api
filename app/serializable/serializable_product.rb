class SerializableProduct < SerializableBase
  type :products

  attribute :name
  attribute :platforms
  attribute :metadata
  attribute :created do
    @object.created_at
  end
  attribute :updated do
    @object.updated_at
  end

  has_many :tokens
  has_many :policies do
    link :related do
      @url_helpers.v1_policies_path product: @object.hashid
    end
  end
  has_many :licenses do
    link :related do
      @url_helpers.v1_licenses_path product: @object.hashid
    end
  end
  has_many :machines do
    link :related do
      @url_helpers.v1_machines_path product: @object.hashid
    end
  end
  has_many :users do
    link :related do
      @url_helpers.v1_users_path product: @object.hashid
    end
  end

  link :self do
    @url_helpers.v1_product_url @object.hashid, host: "keygen.sh"
  end
end
