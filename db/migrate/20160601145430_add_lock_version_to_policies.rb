# frozen_string_literal: true

class AddLockVersionToPolicies < ActiveRecord::Migration[5.0]
  def change
    add_column :policies, :lock_version, :integer, default: 0, null: false
  end
end
