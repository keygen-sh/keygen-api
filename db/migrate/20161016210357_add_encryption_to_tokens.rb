# frozen_string_literal: true

class AddEncryptionToTokens < ActiveRecord::Migration[5.0]
  def up
    rename_column :tokens, :auth_token, :digest
    remove_column :tokens, :reset_token
    remove_index :tokens, :digest
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
