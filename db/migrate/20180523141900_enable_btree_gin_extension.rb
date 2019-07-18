# frozen_string_literal: true

class EnableBtreeGinExtension < ActiveRecord::Migration[5.0]
  def change
    enable_extension 'btree_gin'
  end
end
