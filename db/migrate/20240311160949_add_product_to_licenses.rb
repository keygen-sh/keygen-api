class AddProductToLicenses < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_column :licenses, :product_id, :uuid, null: true

    add_index :licenses, :product_id, algorithm: :concurrently

    # FIXME(ezekg) Move to db/scripts?
    Policy.find_each do |policy|
      policy.licenses.update_all(product_id: policy.product_id)
    end
  end
end
