# frozen_string_literal: true

class UpdateFloatingForPolicies < ActiveRecord::Migration[5.0]
  def change
    change_column_default :policies, :floating, false
  end
end
