class AddSemverComponentsToReleases < ActiveRecord::Migration[7.0]
  def change
    add_column :releases, :semver_major,      :integer
    add_column :releases, :semver_minor,      :integer
    add_column :releases, :semver_patch,      :integer
    add_column :releases, :semver_prerelease, :string
    add_column :releases, :semver_build,      :string

    add_index :releases, %i[semver_major semver_minor semver_patch semver_prerelease semver_build product_id account_id],
      name: :releases_uniq_semver_components_idx,
      where: %(api_version != '1.0'),
      unique: true
  end
end
