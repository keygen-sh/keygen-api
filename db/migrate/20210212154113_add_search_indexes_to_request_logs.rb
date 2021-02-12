class AddSearchIndexesToRequestLogs < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  COLUMNS = [
    :request_id,
    :status,
    :method,
    :url,
    :ip,
  ]

  def change
    COLUMNS.each do |column|
      idx_statement =
        if column == :url
          %[to_tsvector('pg_catalog.simple', regexp_replace(coalesce(#{column}::TEXT, ''), '[^\\w]+', ' ', 'gi'))]
        else
          %[to_tsvector('pg_catalog.simple', coalesce(#{column}::TEXT, ''))]
        end

      add_index :request_logs, idx_statement,
                name: "request_logs_tsv_#{column}_idx",
                algorithm: :concurrently,
                using: :gist
    end
  end
end
