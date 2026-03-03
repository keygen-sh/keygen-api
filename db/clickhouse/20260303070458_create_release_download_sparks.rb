# frozen_string_literal: true

class CreateReleaseDownloadSparks < ActiveRecord::Migration[8.1]
  verbose!

  def up
    create_table :release_download_sparks, id: false,
      options: "MergeTree PARTITION BY toYYYYMM(created_date) ORDER BY (account_id, created_date, product_id, release_id)",
      force: :cascade do |t|
      t.uuid :account_id, null: false
      t.uuid :environment_id, null: true
      t.uuid :product_id, null: false
      t.uuid :package_id, null: true
      t.uuid :release_id, null: false
      t.column :count, "UInt64", null: false, default: 0
      t.date :created_date, null: false
      t.datetime :created_at, precision: 3, null: false

      t.index :environment_id, name: "idx_environment", type: "bloom_filter", granularity: 4
      t.index :package_id, name: "idx_package", type: "bloom_filter", granularity: 4
    end
  end

  def down
    drop_table :release_download_sparks
  end
end
