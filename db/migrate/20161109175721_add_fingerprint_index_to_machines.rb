# frozen_string_literal: true

class AddFingerprintIndexToMachines < ActiveRecord::Migration[5.0]
  def change
    add_index :machines, :fingerprint
  end
end
