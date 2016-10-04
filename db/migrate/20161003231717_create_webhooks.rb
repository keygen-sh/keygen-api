class CreateWebhooks < ActiveRecord::Migration[5.0]
  def change
    create_table :webhooks do |t|
      t.integer :account_id
      t.string :endpoint

      t.timestamps
    end
  end
end
