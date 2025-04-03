class AddDistributionLimitsToPlans < ActiveRecord::Migration[7.2]
  verbose!

  def change
    add_column :plans, :max_storage,  :bigint
    add_column :plans, :max_transfer, :bigint
    add_column :plans, :max_upload,   :bigint
  end
end
