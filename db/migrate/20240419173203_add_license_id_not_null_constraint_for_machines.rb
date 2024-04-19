class AddLicenseIdNotNullConstraintForMachines < ActiveRecord::Migration[7.1]
  def up
    add_check_constraint :machines, 'license_id IS NOT NULL', name: 'machines_license_id_null', validate: false
  end
end
