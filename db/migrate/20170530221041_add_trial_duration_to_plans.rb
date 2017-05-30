class AddTrialDurationToPlans < ActiveRecord::Migration[5.0]
  def change
    add_column :plans, :trial_duration, :integer
  end
end
