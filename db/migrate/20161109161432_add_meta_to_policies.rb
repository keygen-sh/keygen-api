# frozen_string_literal: true

class AddMetaToPolicies < ActiveRecord::Migration[5.0]
  def change
    add_column :policies, :meta, :string
  end
end
