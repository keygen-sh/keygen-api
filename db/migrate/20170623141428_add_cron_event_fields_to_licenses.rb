class AddCronEventFieldsToLicenses < ActiveRecord::Migration[5.0]
  def change
    add_column :licenses, :last_expiring_soon_event_sent_at, :datetime
    add_column :licenses, :last_check_in_soon_event_sent_at, :datetime
  end
end
