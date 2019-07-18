# frozen_string_literal: true

class AddActivationFieldsToTokens < ActiveRecord::Migration[5.0]
  def change
    add_column :tokens, :max_activations, :integer
    add_column :tokens, :max_deactivations, :integer

    add_column :tokens, :activations, :integer, default: 0
    add_column :tokens, :deactivations, :integer, default: 0
  end
end
