class ChangeFilesizeToBigintForReleases < ActiveRecord::Migration[6.1]
  def up
    change_column :releases, :filesize, :bigint
  end

  def down
    change_column :releases, :filesize, :integer
  end
end
