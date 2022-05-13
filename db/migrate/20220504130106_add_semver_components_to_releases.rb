class AddSemverComponentsToReleases < ActiveRecord::Migration[7.0]
  def change
    add_column :releases, :semver_major,      :bigint
    add_column :releases, :semver_minor,      :bigint
    add_column :releases, :semver_patch,      :bigint
    add_column :releases, :semver_pre_word,   :string
    add_column :releases, :semver_pre_num,    :bigint
    add_column :releases, :semver_build_word, :string
    add_column :releases, :semver_build_num,  :bigint

    # Sorting index
    add_index :releases, <<~SQL.squish, name: :releases_sort_semver_components_idx
      semver_major      DESC,
      semver_minor      DESC NULLS LAST,
      semver_patch      DESC NULLS LAST,
      semver_pre_word   DESC NULLS FIRST,
      semver_pre_num    DESC NULLS LAST,
      semver_build_word DESC NULLS LAST,
      semver_build_num  DESC NULLS LAST
    SQL
  end
end
