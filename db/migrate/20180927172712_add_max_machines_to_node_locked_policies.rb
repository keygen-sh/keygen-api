# frozen_string_literal: true

class AddMaxMachinesToNodeLockedPolicies < ActiveRecord::Migration[5.0]
  def change
    policies = Policy.where floating: false
    policies.update_all max_machines: 1
  end
end
