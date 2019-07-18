# frozen_string_literal: true

class AddUrlToProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :url, :string
  end
end
