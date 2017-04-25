class AddPrivateToPlans < ActiveRecord::Migration[5.0]
  def change
    add_column :plans, :private, :boolean, default: false
  end
end
