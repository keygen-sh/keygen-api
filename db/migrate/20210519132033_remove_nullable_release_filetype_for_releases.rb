class RemoveNullableReleaseFiletypeForReleases < ActiveRecord::Migration[6.1]
  def change
    change_column :releases, :release_filetype_id, :uuid, null: false
  end
end
