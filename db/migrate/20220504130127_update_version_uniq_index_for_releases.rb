class UpdateVersionUniqIndexForReleases < ActiveRecord::Migration[7.0]
  def change
    remove_index :releases, %i[account_id product_id release_platform_id release_channel_id release_filetype_id version],
      name: :releases_acct_prod_plat_chan_type_ver_idx

    add_index :releases, %i[version product_id account_id],
      where: %(api_version != '1.0'),
      unique: true
  end
end
