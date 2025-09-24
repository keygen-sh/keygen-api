class AddCoreCounterConstraintForLicenses < ActiveRecord::Migration[7.2]
  verbose!

  def change
    add_check_constraint :licenses, 'machines_core_count IS NOT NULL', name: 'licenses_machines_core_count_null', validate: false
  end
end
