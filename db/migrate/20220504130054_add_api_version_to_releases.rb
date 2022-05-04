class AddApiVersionToReleases < ActiveRecord::Migration[7.0]
  def change
    add_column :releases, :api_version, :string, null: true
  end
end
