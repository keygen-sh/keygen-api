class ValidateLicenseIdNotNullConstraintForMachines < ActiveRecord::Migration[7.1]
  def up
    validate_check_constraint :machines, name: 'machines_license_id_null'

    change_column_null :machines, :license_id, false
    remove_check_constraint :machines, name: 'machines_license_id_null'
  end
end
