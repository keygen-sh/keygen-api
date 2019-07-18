# frozen_string_literal: true

class AddActiveMachinesToLicenses < ActiveRecord::Migration[5.0]
  def change
    add_column :licenses, :active_machines, :string
  end
end
