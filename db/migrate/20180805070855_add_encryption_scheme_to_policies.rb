class AddEncryptionSchemeToPolicies < ActiveRecord::Migration[5.0]
  def change
    add_column :policies, :encryption_scheme, :string

    # Mark all older policies with the legacy scheme
    legacy_policies = Policy.where encrypted: true, encryption_scheme: nil
    legacy_policies.update_all encryption_scheme: 'LEGACY_ENCRYPT'
  end
end
