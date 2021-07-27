class AddContentInfoToReleaseArtifacts < ActiveRecord::Migration[6.1]
  def change
    add_column :release_artifacts, :content_length, :integer
    add_column :release_artifacts, :content_type, :string
  end
end
