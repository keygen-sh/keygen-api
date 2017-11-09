class Receipt < ApplicationRecord
  belongs_to :billing

  scope :unpaid, -> { where paid: false }
  scope :paid, -> { where paid: true }
end

# == Schema Information
#
# Table name: receipts
#
#  id         :uuid             not null, primary key
#  invoice_id :string
#  amount     :integer
#  paid       :boolean
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  billing_id :uuid
#
# Indexes
#
#  index_receipts_on_billing_id_and_created_at  (billing_id,created_at)
#  index_receipts_on_id_and_created_at          (id,created_at) UNIQUE
#
