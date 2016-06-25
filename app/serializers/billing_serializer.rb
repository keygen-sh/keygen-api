class BillingSerializer < BaseSerializer
  attributes :id, :external_customer_id, :external_subscription_id,
    :external_status, :created, :updated

  belongs_to :customer, polymorphic: true

  def id
    object.hashid
  end

  def created
    object.created_at
  end

  def updated
    object.updated_at
  end
end
