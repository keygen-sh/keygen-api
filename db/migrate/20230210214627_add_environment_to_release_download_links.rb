class AddEnvironmentToReleaseDownloadLinks < ActiveRecord::Migration[7.0]
  def change
    add_column :release_download_links, :environment_id, :uuid, null: true

    add_index :release_download_links, :environment_id
  end
end
