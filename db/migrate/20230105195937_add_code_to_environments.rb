class AddCodeToEnvironments < ActiveRecord::Migration[7.0]
  def change
    add_column :environments, :code, :string, null: false

    add_index :environments, %i[account_id code], unique: true
    add_index :environments, :code
  end
end
