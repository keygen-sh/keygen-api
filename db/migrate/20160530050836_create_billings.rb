class CreateBillings < ActiveRecord::Migration[5.0]
  def change
    create_table :billings do |t|
      t.string :stripe_id
      t.string :status

      t.timestamps
    end
  end
end
