class AddMaxMemoryAndDiskOverridesToLicenses < ActiveRecord::Migration[7.0]
  def change
    add_column :licenses, :max_memory_override, :bigint
    add_column :licenses, :max_disk_override, :bigint
  end
end
