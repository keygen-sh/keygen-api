# frozen_string_literal: true

class CreateRequestSparks < ActiveRecord::Migration[8.1]
  verbose!

  def up
    create_table :request_sparks, id: false,
      options: "MergeTree PARTITION BY toYYYYMM(created_date) ORDER BY (account_id, created_date)",
      force: :cascade do |t|
      t.uuid :account_id, null: false
      t.uuid :environment_id, null: true
      t.column :status, "UInt16", null: false
      t.column :count, "UInt64", null: false, default: 0
      t.date :created_date, null: false
      t.datetime :created_at, precision: 3, null: false

      t.index :environment_id, name: "idx_environment", type: "bloom_filter", granularity: 4
      t.index :status, name: "idx_status", type: "set(100)", granularity: 4
    end
  end

  def down
    drop_table :request_sparks
  end
end
