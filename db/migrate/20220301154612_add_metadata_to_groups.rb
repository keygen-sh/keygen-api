class AddMetadataToGroups < ActiveRecord::Migration[6.1]
  def change
    add_column :groups, :metadata, :jsonb, null: true
  end
end
