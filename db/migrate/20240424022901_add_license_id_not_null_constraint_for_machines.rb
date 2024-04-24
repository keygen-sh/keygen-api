class AddLicenseIdNotNullConstraintForMachines < ActiveRecord::Migration[7.1]
  verbose!

  def up
    add_check_constraint :machines, 'license_id IS NOT NULL', name: 'machines_license_id_not_null', validate: false
  end
end
