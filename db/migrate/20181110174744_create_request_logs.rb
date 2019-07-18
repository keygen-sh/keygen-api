# frozen_string_literal: true

class CreateRequestLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :request_logs, id: :uuid, default: -> { "uuid_generate_v4()" } do |t|
      t.uuid :account_id
      t.string :request_id
      t.string :url
      t.string :method
      t.string :ip
      t.string :user_agent
      t.string :status

      t.timestamps
    end

    add_index :request_logs, [:account_id, :created_at]
    add_index :request_logs, [:id, :created_at], unique: true
  end
end
