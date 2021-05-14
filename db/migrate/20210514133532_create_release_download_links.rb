class CreateReleaseDownloadLinks < ActiveRecord::Migration[6.1]
  def change
    create_table :release_download_links, id: :uuid, default: -> { "uuid_generate_v4()" } do |t|
      t.uuid :account_id, null: false
      t.uuid :release_id, null: false

      t.text :url
      t.integer :ttl

      t.timestamps

      t.index %i[account_id created_at], order: { created_at: :desc }
      t.index %i[release_id]
    end
  end
end
