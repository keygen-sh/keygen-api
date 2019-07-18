# frozen_string_literal: true

class AddIndexToTokenDigest < ActiveRecord::Migration[5.0]
  def change
    add_index :tokens, [:digest, :created_at, :account_id], unique: true
  end
end
