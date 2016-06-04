class BillingSerializer < BaseSerializer
  attributes :id, :stripe_id, :status

  belongs_to :customer, polymorphic: true

  def id
    object.hashid
  end
end
