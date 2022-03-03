class AddGroupIdToLicenses < ActiveRecord::Migration[6.1]
  def change
    add_column :licenses, :group_id, :uuid, null: true
  end
end
