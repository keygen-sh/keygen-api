class ChangeNameTsvGinIndexToGistForLicenses < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    remove_index :licenses, %(to_tsvector('pg_catalog.simple', coalesce(name::TEXT, ''))),
      name: :licenses_tsv_name_idx,
      algorithm: :concurrently,
      using: :gin

    add_index :licenses, %(to_tsvector('pg_catalog.simple', coalesce(name::TEXT, ''))),
      name: :licenses_tsv_name_idx,
      algorithm: :concurrently,
      using: :gist
  end
end
