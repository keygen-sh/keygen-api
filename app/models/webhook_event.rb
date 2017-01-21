class WebhookEvent < ApplicationRecord
  include Idempotentable
  include Limitable
  include Pageable

  belongs_to :account

  validates :account, presence: { message: "must exist" }
  validates :endpoint, url: true, presence: true

  def status
    Sidekiq::Status.status(jid) || :working rescue :unavailable
  end
end

# == Schema Information
#
# Table name: webhook_events
#
#  payload           :text
#  jid               :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  endpoint          :string
#  id                :uuid             not null, primary key
#  account_id        :uuid
#  idempotency_token :string
#  event             :string
#
# Indexes
#
#  index_webhook_events_on_created_at_and_account_id  (created_at,account_id)
#  index_webhook_events_on_created_at_and_id          (created_at,id) UNIQUE
#  index_webhook_events_on_created_at_and_jid         (created_at,jid)
#
