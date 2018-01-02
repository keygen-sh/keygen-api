class AddConcurrentToPolicies < ActiveRecord::Migration[5.0]
  def change
    add_column :policies, :concurrent, :boolean, default: true
  end
end
