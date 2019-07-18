# frozen_string_literal: true

class ChangeMetaColumnType < ActiveRecord::Migration[5.0]
  def up
    remove_column :licenses, :meta
    add_column :licenses, :meta, :json

    remove_column :machines, :meta
    add_column :machines, :meta, :json

    remove_column :policies, :meta
    add_column :policies, :meta, :json

    remove_column :products, :platforms
    add_column :products, :platforms, :json

    remove_column :products, :meta
    add_column :products, :meta, :json

    remove_column :users, :meta
    add_column :users, :meta, :json
  end
end
