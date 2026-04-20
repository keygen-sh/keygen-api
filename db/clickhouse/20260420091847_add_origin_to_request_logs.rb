# frozen_string_literal: true

class AddOriginToRequestLogs < ActiveRecord::Migration[8.1]
  verbose!

  def change
    add_column :request_logs, :origin, :string, low_cardinality: true, null: false, default: 'api'

    add_index :request_logs, :origin, name: 'idx_origin', type: 'set(10)', granularity: 4
  end
end
