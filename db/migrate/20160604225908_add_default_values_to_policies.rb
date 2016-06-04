class AddDefaultValuesToPolicies < ActiveRecord::Migration[5.0]

  def up
    change_column_default :policies, :strict,    false
    change_column_default :policies, :recurring, false
    change_column_default :policies, :floating,  true
    change_column_default :policies, :use_pool,  false
  end

  def down
    change_column_default :policies, :strict,    nil
    change_column_default :policies, :recurring, nil
    change_column_default :policies, :floating,  nil
    change_column_default :policies, :use_pool,  nil
  end
end
