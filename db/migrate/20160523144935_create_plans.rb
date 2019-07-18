# frozen_string_literal: true

class CreatePlans < ActiveRecord::Migration[5.0]
  def change
    create_table :plans do |t|
      t.string :name
      t.integer :price
      t.integer :max_users
      t.integer :max_policies
      t.integer :max_licenses

      t.timestamps
    end
  end
end
