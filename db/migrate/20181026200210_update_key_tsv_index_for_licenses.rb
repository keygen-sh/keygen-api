# frozen_string_literal: true

class UpdateKeyTsvIndexForLicenses < ActiveRecord::Migration[5.0]
  def up
    remove_index :licenses, name: :licenses_tsv_key_idx

    add_index :licenses, %[to_tsvector('pg_catalog.simple', left(coalesce(key::TEXT, ''), 128))],
      name: "licenses_tsv_key_idx",
      using: :gin
  end

  def down
    remove_index :licenses, name: :licenses_tsv_key_idx

    add_index :licenses, %[to_tsvector('pg_catalog.simple', coalesce(key::TEXT, ''))],
      name: "licenses_tsv_key_idx",
      using: :gin
  end
end
