class AddEnvironmentToReleaseUploadLinks < ActiveRecord::Migration[7.0]
  def change
    add_column :release_upload_links, :environment_id, :uuid, null: true

    add_index :release_upload_links, :environment_id
  end
end
