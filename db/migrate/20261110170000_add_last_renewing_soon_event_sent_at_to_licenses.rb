# frozen_string_literal: true

class AddLastRenewingSoonEventSentAtToLicenses < ActiveRecord::Migration[8.1]
  verbose!

  def change
    add_column :licenses, :last_renewing_soon_event_sent_at, :datetime, null: true, if_not_exists: true
  end
end
