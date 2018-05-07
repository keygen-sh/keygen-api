class AddConsentFieldsToAccounts < ActiveRecord::Migration[5.0]
  def change
    # Email communication
    add_column :accounts, :accepted_comms, :boolean
    add_column :accounts, :accepted_comms_at, :timestamp
    add_column :accounts, :accepted_comms_rev, :integer

    # Terms of service
    add_column :accounts, :accepted_tos, :boolean
    add_column :accounts, :accepted_tos_at, :timestamp
    add_column :accounts, :accepted_tos_rev, :integer

    # Privacy policy
    add_column :accounts, :accepted_pp, :boolean
    add_column :accounts, :accepted_pp_at, :timestamp
    add_column :accounts, :accepted_pp_rev, :integer
  end
end
