class WebhookEvent < ApplicationRecord
  include Idempotentable
  include Limitable
  include Pageable

  belongs_to :account

  validates :account, presence: { message: "must exist" }
  validates :endpoint, url: true, presence: true

  def status
    Sidekiq::Status.status(jid) || :complete rescue :unavailable
  end
end

# == Schema Information
#
# Table name: webhook_events
#
#  id                :uuid             not null, primary key
#  payload           :text
#  jid               :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  endpoint          :string
#  deleted_at        :datetime
#  account_id        :uuid
#  idempotency_token :string
#
# Indexes
#
#  index_webhook_events_on_account_id  (account_id)
#  index_webhook_events_on_created_at  (created_at)
#  index_webhook_events_on_jid         (jid)
#
