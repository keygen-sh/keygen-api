# frozen_string_literal: true

class SerializableMetric < SerializableBase
  type :metrics

  attribute :metric do
    @object.event_type.event
  end
  attribute :data
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
    @url_helpers.v1_account_metric_path @object.account_id, @object
  end
end
