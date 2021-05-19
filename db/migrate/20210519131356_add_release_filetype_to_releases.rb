class AddReleaseFiletypeToReleases < ActiveRecord::Migration[6.1]
  def change
    add_column :releases, :release_filetype_id, :uuid
    add_index :releases, %i[release_filetype_id]

    remove_index :releases, name: :releases_acct_prod_plat_chan_version_idx, if_exists: true
    add_index :releases,
      %i[account_id product_id release_platform_id release_channel_id release_filetype_id version],
      name: :releases_acct_prod_plat_chan_type_ver_idx,
      unique: true
  end
end
