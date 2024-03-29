# frozen_string_literal: true

class CreateEventLogs < ActiveRecord::Migration[6.1]
  def change
    create_table :event_logs, id: :uuid, default: -> { "uuid_generate_v4()" } do |t|
      t.references :account,     type: :uuid, null: false
      t.references :event_type,  type: :uuid, null: false
      t.references :resource,    type: :uuid, null: false, polymorphic: true
      t.references :whodunnit,   type: :uuid, null: true,  polymorphic: true
      t.references :request_log, type: :uuid, null: true

      t.string :idempotency_key, index: { unique: true }
      t.jsonb  :metadata

      t.timestamps
    end
  end
end
