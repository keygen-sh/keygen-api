# frozen_string_literal: true

class RenameAasmStateToStateForBillings < ActiveRecord::Migration[5.0]
  def change
    rename_column :billings, :aasm_state, :state
  end
end
