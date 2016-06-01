class BillingSerializer < BaseSerializer
  attributes :id, :stripe_id, :status
  belongs_to :customer, polymorphic: true
end
