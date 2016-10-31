class WebhookEventSerializer < BaseSerializer
  type :webhook_events

  attributes [
    :endpoint,
    :payload,
    :status
  ]

  belongs_to :account
end

# == Schema Information
#
# Table name: webhook_events
#
#  id         :integer          not null, primary key
#  account_id :integer
#  payload    :string
#  jid        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  endpoint   :string
#
# Indexes
#
#  index_webhook_events_on_account_id  (account_id)
#  index_webhook_events_on_jid         (jid)
#
