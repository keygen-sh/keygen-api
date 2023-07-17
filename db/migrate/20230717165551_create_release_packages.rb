class CreateReleasePackages < ActiveRecord::Migration[7.0]
  def change
    create_table :release_packages, id: :uuid, default: -> { 'uuid_generate_v4()' } do |t|
      t.uuid :account_id,        null: false
      t.uuid :product_id,        null: false
      t.uuid :release_engine_id, null: true
      t.uuid :environment_id,    null: true

      t.string :name, null: false
      t.string :key,  null: false
      t.jsonb :metadata

      t.timestamps

      t.index %i[account_id created_at], order: { created_at: :desc }
      t.index %i[account_id key], unique: true
      t.index %i[environment_id]
      t.index %i[product_id]
      t.index %i[release_engine_id]
    end
  end
end
