# frozen_string_literal: true

class CreateMachines < ActiveRecord::Migration[5.0]
  def change
    create_table :machines do |t|
      t.string :fingerprint
      t.string :ip
      t.string :hostname
      t.string :platform
      t.integer :account_id
      t.integer :license_id

      t.timestamps
    end
  end
end
