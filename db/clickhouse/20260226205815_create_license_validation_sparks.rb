# frozen_string_literal: true

class CreateLicenseValidationSparks < ActiveRecord::Migration[8.1]
  verbose!

  def up
    create_table :license_validation_sparks, id: false,
      options: "MergeTree PARTITION BY toYYYYMM(created_date) ORDER BY (account_id, created_date, license_id)",
      force: :cascade do |t|
      t.uuid :account_id, null: false
      t.uuid :environment_id, null: true
      t.uuid :license_id, null: false
      t.string :validation_code, low_cardinality: true, null: false
      t.column :count, "UInt64", null: false, default: 0
      t.date :created_date, null: false
      t.datetime :created_at, precision: 3, null: false

      t.index :environment_id, name: "idx_environment", type: "bloom_filter", granularity: 4
      t.index :validation_code, name: "idx_validation_code", type: "bloom_filter", granularity: 4
    end
  end

  def down
    drop_table :license_validation_sparks
  end
end
