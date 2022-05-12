class AddSemverComponentsToReleases < ActiveRecord::Migration[7.0]
  def change
    add_column :releases, :semver_major,      :bigint
    add_column :releases, :semver_minor,      :bigint
    add_column :releases, :semver_patch,      :bigint
    add_column :releases, :semver_pre_word,   :string
    add_column :releases, :semver_pre_num,    :bigint
    add_column :releases, :semver_build_word, :string
    add_column :releases, :semver_build_num,  :bigint

    add_index :releases, %i[semver_major semver_minor semver_patch semver_pre_word semver_pre_num semver_build_word semver_build_num product_id account_id],
      name: :releases_uniq_semver_components_idx,
      where: %(api_version != '1.0'),
      unique: true

    add_index :releases, %i[semver_major semver_minor semver_patch semver_pre_word semver_pre_num semver_build_word semver_build_num product_id account_id],
      name: :releases_v1_0_semver_components_idx,
      where: %(api_version = '1.0')
  end
end
