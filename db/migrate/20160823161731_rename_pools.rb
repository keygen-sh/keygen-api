# frozen_string_literal: true

class RenamePools < ActiveRecord::Migration[5.0]
  def change
    rename_table :pools, :keys
  end
end
