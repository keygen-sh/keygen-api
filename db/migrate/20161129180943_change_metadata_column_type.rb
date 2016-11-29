class ChangeMetadataColumnType < ActiveRecord::Migration[5.0]
  def change
    remove_column :licenses, :metadata
    add_column :licenses, :metadata, :jsonb

    remove_column :machines, :metadata
    add_column :machines, :metadata, :jsonb

    remove_column :policies, :metadata
    add_column :policies, :metadata, :jsonb

    remove_column :products, :platforms
    add_column :products, :platforms, :jsonb

    remove_column :products, :metadata
    add_column :products, :metadata, :jsonb

    remove_column :users, :metadata
    add_column :users, :metadata, :jsonb
  end
end
