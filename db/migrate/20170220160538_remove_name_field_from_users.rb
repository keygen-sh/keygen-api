# frozen_string_literal: true

class RemoveNameFieldFromUsers < ActiveRecord::Migration[5.0]
  def change
    remove_column :users, :name, :string
  end
end
