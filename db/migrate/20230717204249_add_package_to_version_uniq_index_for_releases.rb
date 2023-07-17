class AddPackageToVersionUniqIndexForReleases < ActiveRecord::Migration[7.0]
  def change
    remove_index :releases, %i[version product_id account_id],
      unique: true,
      where: <<~SQL.squish
        api_version != '1.0'
      SQL

    # FIXME(ezekg) Postgres < v15 doesn't support NULLS NOT DISTINCT, so we're
    #              creating 2 separate unique indexes.
    add_index :releases, %i[version product_id account_id],
      name: :releases_version_no_package_uniq_idx,
      unique: true,
      where: <<~SQL.squish
        release_package_id IS NULL AND
        api_version != '1.0'
      SQL

    add_index :releases, %i[version release_package_id product_id account_id],
      name: :releases_version_package_uniq_idx,
      unique: true,
      where: <<~SQL.squish
        release_package_id IS NOT NULL AND
        api_version != '1.0'
      SQL
  end
end
