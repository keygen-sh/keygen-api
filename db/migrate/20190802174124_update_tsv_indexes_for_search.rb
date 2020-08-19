# frozen_string_literal: true

class UpdateTsvIndexesForSearch < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  INDEXES = {
    products: %i[id name metadata],
    policies: %i[id name metadata],
    licenses: %i[id key metadata],
    machines: %i[id fingerprint name metadata],
    users: %i[id email first_name last_name metadata],
    keys: %i[id key]
  }

  def change
    INDEXES.each do |table, columns|
      columns.each do |column|
        remove_index table, name: "#{table}_tsv_#{column}_idx", algorithm: :concurrently

        if table == :machines && column == :fingerprint ||
           table == :licenses && column == :key ||
           table == :keys && column == :key
          add_index table, %[to_tsvector('pg_catalog.simple', left(coalesce(#{column}::TEXT, ''), 128))],
            name: "#{table}_tsv_#{column}_idx",
            algorithm: :concurrently,
            using: :gist
        else
          add_index table, %[to_tsvector('pg_catalog.simple', coalesce(#{column}::TEXT, ''))],
            name: "#{table}_tsv_#{column}_idx",
            algorithm: :concurrently,
            using: :gist
        end
      end
    end
  end
end
