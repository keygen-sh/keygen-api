class BillingSerializer < BaseSerializer
  attributes :id, :external_customer_id, :status

  belongs_to :customer, polymorphic: true

  def id
    object.hashid
  end
end
