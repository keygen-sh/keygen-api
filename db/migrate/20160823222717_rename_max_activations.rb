class RenameMaxActivations < ActiveRecord::Migration[5.0]
  def change
    rename_column :policies, :max_activations, :max_machines
  end
end
