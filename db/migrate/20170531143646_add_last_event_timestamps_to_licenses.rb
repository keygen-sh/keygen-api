# frozen_string_literal: true

class AddLastEventTimestampsToLicenses < ActiveRecord::Migration[5.0]
  def change
    add_column :licenses, :last_expiration_event_sent_at, :datetime
    add_column :licenses, :last_check_in_event_sent_at, :datetime
  end
end
