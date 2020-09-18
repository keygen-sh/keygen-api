class CreateSecondFactors < ActiveRecord::Migration[5.2]
  def change
    create_table :second_factors, id: :uuid, default: -> { "uuid_generate_v4()" } do |t|
      t.uuid :account_id, null: false
      t.uuid :user_id, null: false
      t.text :secret, null: false
      t.boolean :enabled, null: false, default: false

      t.timestamps
    end

    add_index :second_factors, [:id, :created_at], unique: true
    add_index :second_factors, [:account_id, :created_at]
    add_index :second_factors, [:user_id, :created_at]
    add_index :second_factors, :user_id, unique: true
    add_index :second_factors, :secret, unique: true
    add_index :second_factors, :enabled
  end
end
