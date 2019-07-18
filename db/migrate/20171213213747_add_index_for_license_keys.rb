# frozen_string_literal: true

class AddIndexForLicenseKeys < ActiveRecord::Migration[5.0]
  def change
    add_index :licenses, [:key, :created_at, :account_id]
  end
end
