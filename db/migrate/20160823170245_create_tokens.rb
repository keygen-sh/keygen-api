# frozen_string_literal: true

class CreateTokens < ActiveRecord::Migration[5.0]
  def change
    create_table :tokens do |t|
      t.string :auth_token
      t.string :reset_token
      t.integer :bearer_id
      t.string :bearer_type

      t.timestamps
    end
  end
end
