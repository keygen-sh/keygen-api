# frozen_string_literal: true

class CreateLicenseSparks < ActiveRecord::Migration[8.1]
  def up
    create_table :license_sparks, id: false, options: 'MergeTree PARTITION BY toYYYYMM(created_date) ORDER BY (account_id, created_date, environment_id) SETTINGS allow_nullable_key = 1', force: :cascade do |t|
      t.uuid :account_id, null: false
      t.uuid :environment_id, null: true
      t.column :count, "UInt64", null: false, default: 0
      t.date :created_date, null: false
      t.datetime :created_at, precision: 3, null: false
    end
  end

  def down
    drop_table :license_sparks
  end
end
