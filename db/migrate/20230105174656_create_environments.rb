class CreateEnvironments < ActiveRecord::Migration[7.0]
  def change
    create_table :environments, id: :uuid, default: -> { 'uuid_generate_v4()' } do |t|
      t.uuid :account_id, null: false

      t.string :name, null: false

      t.timestamps

      t.index %i[account_id created_at], order: { created_at: :desc }
    end
  end
end
