class AddLicenseAuthStrategyToPolicies < ActiveRecord::Migration[6.1]
  def change
    add_column :policies, :license_auth_strategy, :string, null: true
  end
end
