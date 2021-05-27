class AddReferralIdToBillings < ActiveRecord::Migration[6.1]
  def change
    add_column :billings, :referral_id, :string
  end
end
