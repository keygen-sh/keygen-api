# frozen_string_literal: true

class AddNameTsvIndexToLicenses < ActiveRecord::Migration[5.0]
  def change
    add_index :licenses, %[to_tsvector('pg_catalog.simple', coalesce(name::TEXT, ''))],
      name: "licenses_tsv_name_idx",
      using: :gin
  end
end
