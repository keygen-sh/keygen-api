class UpdateTagUniqIndexForReleases < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    remove_index :releases, %i[tag account_id], algorithm: :concurrently

    # FIXME(ezekg) Postgres < v15 doesn't support NULLS NOT DISTINCT, so we're
    #              creating 2 separate unique indexes.
    add_index :releases, %i[tag account_id product_id],
      name: :releases_tag_no_package_uniq_idx,
      algorithm: :concurrently,
      unique: true,
      where: <<~SQL.squish
        release_package_id IS NULL
        AND tag IS NOT NULL
      SQL

    add_index :releases, %i[tag account_id product_id release_package_id],
      name: :releases_tag_package_uniq_idx,
      algorithm: :concurrently,
      unique: true,
      where: <<~SQL.squish
        release_package_id IS NOT NULL
        AND tag IS NOT NULL
      SQL
  end
end
