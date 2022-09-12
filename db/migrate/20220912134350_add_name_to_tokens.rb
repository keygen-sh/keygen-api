class AddNameToTokens < ActiveRecord::Migration[7.0]
  def change
    add_column :tokens, :name, :string
  end
end
