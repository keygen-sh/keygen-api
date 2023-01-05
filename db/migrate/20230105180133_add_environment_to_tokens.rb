class AddEnvironmentToTokens < ActiveRecord::Migration[7.0]
  def change
    add_column :tokens, :environment_id, :uuid, null: true

    add_index :tokens, :environment_id
  end
end
