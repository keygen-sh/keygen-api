class RenameSizeToFilesizeForReleases < ActiveRecord::Migration[6.1]
  def change
    rename_column :releases, :size, :filesize
  end
end
