# frozen_string_literal: true

class AddMaxActivationsToPolicy < ActiveRecord::Migration[5.0]
  def change
    add_column :policies, :max_activations, :integer
  end
end
