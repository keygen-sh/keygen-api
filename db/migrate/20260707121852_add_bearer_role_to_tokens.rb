# frozen_string_literal: true

class AddBearerRoleToTokens < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!
  verbose!

  def change
    add_column :tokens, :bearer_role, :string, if_not_exists: true

    add_index :tokens, %i[account_id bearer_role created_at],
      algorithm: :concurrently,
      if_not_exists: true
  end
end
