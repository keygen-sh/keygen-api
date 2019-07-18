# frozen_string_literal: true

class AddStateToBillings < ActiveRecord::Migration[5.0]
  def change
    add_column :billings, :aasm_state, :string
  end
end
