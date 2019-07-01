class AddIndexToMetricData < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :metrics, "to_tsvector('pg_catalog.simple', coalesce(data::TEXT, ''))",
      name: :metrics_tsv_data_idx,
      algorithm: :concurrently,
      using: :gin
  end
end
