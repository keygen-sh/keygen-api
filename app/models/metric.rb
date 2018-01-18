class Metric < ApplicationRecord
  include DateRangeable
  include Limitable
  include Pageable

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
#  index_metrics_on_account_id_and_created_at  (account_id,created_at)
#  index_metrics_on_id_and_created_at          (id,created_at) UNIQUE
#
