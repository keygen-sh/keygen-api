class RemoveEnvironmentFromReleaseArches < ActiveRecord::Migration[7.0]
  def change
    remove_column :release_arches, :environment_id
  end
end
