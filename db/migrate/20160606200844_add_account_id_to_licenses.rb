# frozen_string_literal: true

class AddAccountIdToLicenses < ActiveRecord::Migration[5.0]
  def change
    add_column :licenses, :account_id, :integer
  end
end
