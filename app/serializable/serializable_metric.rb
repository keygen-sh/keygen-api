class SerializableMetric < SerializableBase
  type :metrics

  attribute :metric
  attribute :data
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

  link :self do
    @url_helpers.v1_account_metric_path @object.account, @object
  end
end
