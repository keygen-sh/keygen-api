class AddDescriptionToReleases < ActiveRecord::Migration[6.1]
  def change
    add_column :releases, :description, :text, null: true
  end
end
