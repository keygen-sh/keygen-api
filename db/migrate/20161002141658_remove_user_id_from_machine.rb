# frozen_string_literal: true

class RemoveUserIdFromMachine < ActiveRecord::Migration[5.0]
  def change
    remove_column :machines, :user_id, :integer
  end
end
