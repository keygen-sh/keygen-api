class AddPolicyToMachines < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!
  verbose!

  def change
    add_column :machines, :policy_id, :uuid, null: true, if_not_exists: true

    add_index :machines, :policy_id, algorithm: :concurrently, if_not_exists: true
  end
end
