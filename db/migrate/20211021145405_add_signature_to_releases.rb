class AddSignatureToReleases < ActiveRecord::Migration[6.1]
  def change
    add_column :releases, :signature, :string, null: true
  end
end
