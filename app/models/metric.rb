class Metric < ApplicationRecord
  include DateRangeable
  include Limitable

  belongs_to :account

  validates :account, presence: { message: "must exist" }
  validates :metric, presence: true
  validates :data, presence: true

  scope :metrics, -> (*metrics) { where metric: metrics }
end

# == Schema Information
#
# Table name: metrics
#
#  id         :uuid             not null, primary key
#  account_id :uuid
#  metric     :string
#  data       :jsonb
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_metrics_on_created_at_and_account_id  (created_at,account_id)
#  index_metrics_on_created_at_and_id          (created_at,id) UNIQUE
#
