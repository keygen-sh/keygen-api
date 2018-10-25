class AddIntervalToPlans < ActiveRecord::Migration[5.0]
  def change
    add_column :plans, :interval, :string
  end
end
