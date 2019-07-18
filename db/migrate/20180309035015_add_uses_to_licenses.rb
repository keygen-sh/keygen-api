# frozen_string_literal: true

class AddUsesToLicenses < ActiveRecord::Migration[5.0]
  def change
    add_column :licenses, :uses, :integer, default: 0
  end
end
