# frozen_string_literal: true

class RemoveLicenseIdFromUsers < ActiveRecord::Migration[5.0]
  def change
    remove_column :users, :license_id, :integer
  end
end
