class CreateMetrics < ActiveRecord::Migration[5.0]
  def change
    create_table :metrics, id: :uuid do |t|
      t.uuid :account_id
      t.string :metric
      t.jsonb :data

      t.timestamps
    end
  end
end
