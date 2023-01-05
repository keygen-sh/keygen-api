class AddEnvironmentToReleaseFiletypes < ActiveRecord::Migration[7.0]
  def change
    add_column :release_filetypes, :environment_id, :uuid, null: true

    add_index :release_filetypes, :environment_id
  end
end
