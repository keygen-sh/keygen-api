class RenameReleaseUpdateLinksToReleaseUpgradeLinks < ActiveRecord::Migration[6.1]
  def change
    rename_table :release_update_links, :release_upgrade_links
    rename_column :releases, :update_count, :upgrade_count
  end
end
