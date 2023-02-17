class RemoveEnvironmentFromReleaseFiletypes < ActiveRecord::Migration[7.0]
  def change
    remove_column :release_filetypes, :environment_id
  end
end
