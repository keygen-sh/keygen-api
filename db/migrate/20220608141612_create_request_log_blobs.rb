class CreateRequestLogBlobs < ActiveRecord::Migration[7.0]
  def up
    create_enum :blob_type, %i[request_headers request_body response_headers response_body response_signature]

    create_table :request_log_blobs, id: :uuid, default: -> { "uuid_generate_v4()" } do |t|
      t.uuid :request_log_id, null: false

      t.enum :blob_type, enum_type: :blob_type, null: false
      t.text :blob

      t.timestamps

      t.index %i[request_log_id blob_type]
    end
  end

  def down
    drop_table :request_log_blobs

    execute 'DROP TYPE blob_type'
  end
end
