class WebhookEventSerializer < BaseSerializer
  type :webhook_events

  attributes :endpoint,
             :payload,
             :status
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
#  index_webhook_events_on_id          (id)
#  index_webhook_events_on_jid         (jid)
#
