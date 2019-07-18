# frozen_string_literal: true

class AddSuspendedToLicenses < ActiveRecord::Migration[5.0]
  def change
    add_column :licenses, :suspended, :boolean, default: false
  end
end
