class Billing < ApplicationRecord
  belongs_to :customer, polymorphic: true

  before_destroy :close_external_customer_account!

  validates :external_customer_id, presence: {
    message: "billing details are invalid"
  }

  private

  def close_external_customer_account!
    CustomerService.new(id: external_customer_id).delete
  end
end
