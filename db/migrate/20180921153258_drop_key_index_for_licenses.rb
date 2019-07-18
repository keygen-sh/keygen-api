# frozen_string_literal: true

class DropKeyIndexForLicenses < ActiveRecord::Migration[5.0]
  def change
    remove_index :licenses, name: :index_licenses_on_key_and_created_at_and_account_id
  end
end
