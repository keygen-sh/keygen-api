# frozen_string_literal: true

class RenameMetaToMetadata < ActiveRecord::Migration[5.0]
  def change
    rename_column :licenses, :meta, :metadata

    rename_column :machines, :meta, :metadata

    rename_column :policies, :meta, :metadata

    rename_column :products, :meta, :metadata

    rename_column :users, :meta, :metadata
  end
end
