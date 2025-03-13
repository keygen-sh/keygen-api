class AddNullableTokenIdToSessions < ActiveRecord::Migration[7.2]
  def up
    change_column_null :sessions, :token_id, true
  end

  def down
    change_column_null :sessions, :token_id, false
  end
end
