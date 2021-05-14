class CreateReleases < ActiveRecord::Migration[6.1]
  def change
    create_table :releases, id: :uuid, default: -> { "uuid_generate_v4()" } do |t|
      t.uuid :account_id, null: false
      t.uuid :product_id, null: false
      t.uuid :release_platform_id, null: false
      t.uuid :release_channel_id, null: false

      t.string :name
      t.string :version
      t.string :key
      t.integer :size
      t.boolean :require_license_key, default: true
      t.bigint :download_links_count, default: 0
      t.jsonb :metadata

      t.datetime :yanked_at
      t.timestamps

      # This index will mostly be used for version uniqueness across product + platform + channel
      t.index %i[account_id product_id release_platform_id release_channel_id version], name: :releases_acct_prod_plat_chan_version_idx, unique: true

      t.index %i[account_id created_at yanked_at], order: { created_at: :desc }
      t.index %i[account_id product_id key], unique: true
      t.index %i[account_id product_id require_license_key], name: :releases_acct_prod_req_key_idx
      t.index %i[release_platform_id]
      t.index %i[release_channel_id]
      t.index %i[product_id]
    end
  end
end
