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
#  id         :integer          not null, primary key
#  account_id :integer
#  payload    :text
#  jid        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  endpoint   :string
#  deleted_at :datetime
#
# Indexes
#
#  index_webhook_events_on_account_id_and_id  (account_id,id)
#  index_webhook_events_on_deleted_at         (deleted_at)
#  index_webhook_events_on_jid                (jid)
#
