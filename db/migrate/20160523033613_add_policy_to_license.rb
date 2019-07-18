# frozen_string_literal: true

class AddPolicyToLicense < ActiveRecord::Migration[5.0]
  def change
    add_column :licenses, :policy_id, :integer
  end
end
