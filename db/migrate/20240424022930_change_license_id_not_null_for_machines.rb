class ChangeLicenseIdNotNullForMachines < ActiveRecord::Migration[7.1]
  verbose!

  def up
    change_column_null :machines, :license_id, false
    remove_check_constraint :machines, name: 'machines_license_id_not_null'
  end
end
