# frozen_string_literal: true

class SerializableMetric < SerializableBase
  type :metrics

  attribute :metric do
    # FIXME(ezekg) Backwards compat during deploy
    if @object.event_type.present?
      @object.event_type.event
    else
      @object.metric
    end
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
