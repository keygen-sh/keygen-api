class AddMetaToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :meta, :string
  end
end
