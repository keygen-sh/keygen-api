class AddCoreCounterDefaultToLicenses < ActiveRecord::Migration[7.2]
  verbose!

  def change
    change_column_default :licenses, :machines_core_count, 0
  end
end
