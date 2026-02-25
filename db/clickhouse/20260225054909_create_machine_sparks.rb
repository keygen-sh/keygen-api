# frozen_string_literal: true

class CreateMachineSparks < ActiveRecord::Migration[8.1]
  def up
    create_table :machine_sparks, id: false, options: "MergeTree PARTITION BY toYYYYMM(created_date) ORDER BY (account_id, created_date)", force: :cascade do |t|
      t.uuid :account_id, null: false
      t.uuid :environment_id, null: true
      t.column :count, "UInt64", null: false, default: 0
      t.date :created_date, null: false
      t.datetime :created_at, precision: 3, null: false

      t.index :environment_id, name: "idx_environment", type: "bloom_filter", granularity: 4
    end
  end

  def down
    drop_table :machine_sparks
  end
end
