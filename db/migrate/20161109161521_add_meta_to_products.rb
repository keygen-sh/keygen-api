# frozen_string_literal: true

class AddMetaToProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :meta, :string
  end
end
