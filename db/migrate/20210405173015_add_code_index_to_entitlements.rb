class AddCodeIndexToEntitlements < ActiveRecord::Migration[6.1]
  def change
    add_index :entitlements, :code
  end
end
