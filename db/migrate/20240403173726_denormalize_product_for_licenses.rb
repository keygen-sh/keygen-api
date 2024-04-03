class DenormalizeProductForLicenses < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    Policy.find_each do |policy|
      policy.licenses.in_batches.update_all(product_id: policy.product_id)
    end
  end

  def down
    Policy.find_each do |policy|
      policy.licenses.in_batches.update_all(product_id: nil)
    end
  end
end
