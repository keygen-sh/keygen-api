class ChangeProtectedDefaultForPolicies < ActiveRecord::Migration[5.0]
  def change
    change_column_default :policies, :protected, nil
  end
end
