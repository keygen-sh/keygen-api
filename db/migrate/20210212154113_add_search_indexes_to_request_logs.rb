class AddSearchIndexesToRequestLogs < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index(
      :request_logs,
      %[
        to_tsvector(
          'pg_catalog.simple',
          coalesce(request_id::TEXT, '') || ' ' ||
          coalesce(status::TEXT, '') ||  ' ' ||
          coalesce(method::TEXT, '') || ' ' ||
          coalesce(url::TEXT, '') || ' ' ||
          coalesce(ip::TEXT, '')
        )
      ].squish,
      name: :request_logs_tsv_fuzzy_idx,
      algorithm: :concurrently,
      using: :gist
    )
  end
end
