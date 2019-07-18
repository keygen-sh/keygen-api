# frozen_string_literal: true

class RemoveActivationsFromLicenses < ActiveRecord::Migration[5.0]
  def change
    remove_column :licenses, :activations, :integer
  end
end
