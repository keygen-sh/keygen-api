class RemoveFriendlyIds < ActiveRecord::Migration[5.0]
  def up
    drop_table :friendly_id_slugs
  end
end
