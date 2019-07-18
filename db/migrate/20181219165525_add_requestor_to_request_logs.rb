# frozen_string_literal: true

class AddRequestorToRequestLogs < ActiveRecord::Migration[5.2]
  def change
    add_column :request_logs, :requestor_type, :string
    add_column :request_logs, :requestor_id, :uuid
  end
end
