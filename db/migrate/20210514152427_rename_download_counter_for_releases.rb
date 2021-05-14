class RenameDownloadCounterForReleases < ActiveRecord::Migration[6.1]
  def change
    rename_column :releases, :download_links_count, :download_count
  end
end
