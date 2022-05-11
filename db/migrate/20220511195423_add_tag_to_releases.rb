class AddTagToReleases < ActiveRecord::Migration[7.0]
  def change
    add_column :releases, :tag, :string, null: true

    add_index :releases, %i[tag account_id],
      where: %(tag IS NOT NULL),
      unique: true
  end
end
