class RenameKeyToFilenameForReleases < ActiveRecord::Migration[6.1]
  def change
    rename_column :releases, :key, :filename
  end
end
