class AddUpdateCountToReleases < ActiveRecord::Migration[6.1]
  def change
    add_column :releases, :update_count, :bigint, default: 0
  end
end
