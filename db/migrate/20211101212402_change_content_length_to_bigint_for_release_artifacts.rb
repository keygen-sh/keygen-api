class ChangeContentLengthToBigintForReleaseArtifacts < ActiveRecord::Migration[6.1]
  def up
    change_column :release_artifacts, :content_length, :bigint
  end

  def down
    change_column :release_artifacts, :content_length, :integer
  end
end
