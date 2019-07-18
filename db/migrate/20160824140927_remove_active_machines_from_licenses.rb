# frozen_string_literal: true

class RemoveActiveMachinesFromLicenses < ActiveRecord::Migration[5.0]
  def change
    remove_column :licenses, :active_machines, :string
  end
end
