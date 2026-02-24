class AddIdIndexToRequestLogs < ActiveRecord::Migration[8.1]
  verbose!

  def change
    add_index :request_logs, :id, name: "idx_id", type: "bloom_filter", granularity: 4
  end
end
