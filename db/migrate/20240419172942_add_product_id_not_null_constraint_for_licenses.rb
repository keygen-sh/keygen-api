class AddProductIdNotNullConstraintForLicenses < ActiveRecord::Migration[7.1]
  def up
    add_check_constraint :licenses, 'product_id IS NOT NULL', name: 'licenses_product_id_null', validate: false
  end
end
