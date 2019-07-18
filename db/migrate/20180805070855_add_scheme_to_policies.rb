# frozen_string_literal: true

class AddSchemeToPolicies < ActiveRecord::Migration[5.0]
  def change
    add_column :policies, :scheme, :string

    # Mark all older policies with the legacy scheme
    legacy_policies = Policy.where encrypted: true, scheme: nil
    legacy_policies.update_all scheme: 'LEGACY_ENCRYPT'
  end
end
