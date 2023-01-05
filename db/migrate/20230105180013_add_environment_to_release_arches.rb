class AddEnvironmentToReleaseArches < ActiveRecord::Migration[7.0]
  def change
    add_column :release_arches, :environment_id, :uuid, null: true

    add_index :release_arches, :environment_id
  end
end
