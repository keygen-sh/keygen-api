class Receipt < ApplicationRecord
  acts_as_paranoid

  belongs_to :billing

  scope :unpaid, -> { where paid: false }
  scope :paid, -> { where paid: true }
end

# == Schema Information
#
# Table name: receipts
#
#  invoice_id :string
#  amount     :integer
#  paid       :boolean
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  deleted_at :datetime
#  id         :uuid             not null, primary key
#  billing_id :uuid
#
# Indexes
#
#  index_receipts_on_billing_id  (billing_id)
#  index_receipts_on_created_at  (created_at)
#  index_receipts_on_deleted_at  (deleted_at)
#  index_receipts_on_id          (id)
#
