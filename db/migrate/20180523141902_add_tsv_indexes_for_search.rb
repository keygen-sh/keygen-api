# frozen_string_literal: true

class AddTsvIndexesForSearch < ActiveRecord::Migration[5.0]
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
        add_index table, %[to_tsvector('pg_catalog.simple', coalesce(#{column}::TEXT, ''))],
          name: "#{table}_tsv_#{column}_idx",
          using: :gin
      end
    end
  end
end
