class WebhookEvent < ApplicationRecord
  include Limitable
  include Pageable

  acts_as_paranoid

  belongs_to :account

  validates :account, presence: { message: "must exist" }
  validates :endpoint, url: true, presence: true
  validates :jid, presence: true, uniqueness: true

  def status
    Sidekiq::Status.status jid rescue :unavailable
  end
end

# == Schema Information
#
# Table name: webhook_events
#
#  payload    :text
#  jid        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  endpoint   :string
#  deleted_at :datetime
#  id         :uuid             not null, primary key
#  account_id :uuid
#
# Indexes
#
#  index_webhook_events_on_account_id  (account_id)
#  index_webhook_events_on_created_at  (created_at)
#  index_webhook_events_on_deleted_at  (deleted_at)
#  index_webhook_events_on_jid         (jid)
#
