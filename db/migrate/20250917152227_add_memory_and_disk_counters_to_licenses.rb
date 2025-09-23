class AddMemoryAndDiskCountersToLicenses < ActiveRecord::Migration[7.2]
  def change
    add_column :licenses, :machines_memory_count, :bigint, default: 0, null: false
    add_column :licenses, :machines_disk_count, :bigint, default: 0, null: false
  end
end
