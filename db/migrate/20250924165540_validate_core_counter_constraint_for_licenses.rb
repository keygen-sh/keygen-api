class ValidateCoreCounterConstraintForLicenses < ActiveRecord::Migration[7.2]
  verbose!

  def up
    validate_check_constraint :licenses, name: 'licenses_machines_core_count_null'
    change_column_null :licenses, :machines_core_count, false
    remove_check_constraint :licenses, name: 'licenses_machines_core_count_null'
  end

  def down
    add_check_constraint :licenses, 'machines_core_count IS NOT NULL', name: 'licenses_machines_core_count_null', validate: false
    change_column_null :licenses, :machines_core_count, true
  end
end
