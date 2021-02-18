class RemoveKeyGinIndexFromLicenses < ActiveRecord::Migration[5.2]
  def change
    # FIXME(ezekg) Indexed values were too big and this caused the GIN index to fail
    remove_index :licenses, name: :index_licenses_on_key
  end
end
