class AddNullableReleaseFiletypeForReleases < ActiveRecord::Migration[6.1]
  def up
    change_column :releases, :release_filetype_id, :uuid, null: true
  end

  def down
    change_column :releases, :release_filetype_id, :uuid, null: false
  end
end
