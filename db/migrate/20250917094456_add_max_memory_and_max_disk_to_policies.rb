class AddMaxMemoryAndMaxDiskToPolicies < ActiveRecord::Migration[7.0]
  def change
    add_column :policies, :max_memory, :bigint
    add_column :policies, :max_disk, :bigint
  end
end
