# frozen_string_literal: true

class RemoveTemporaryBearerRoleIndexFromTokens < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!
  verbose!

  INDEX_NAME = :tmp_idx_tokens_id_bearer_role_null

  def up
    remove_index :tokens, name: INDEX_NAME, algorithm: :concurrently, if_exists: true
  end

  def down
    add_index :tokens, :id, name: INDEX_NAME, where: 'bearer_role IS NULL', algorithm: :concurrently, if_not_exists: true
  end
end
