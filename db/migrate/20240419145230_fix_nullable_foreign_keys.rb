class FixNullableForeignKeys < ActiveRecord::Migration[7.1]
  def up
    change_column_null :billings,          :account_id,    false
    change_column_null :keys,              :account_id,    false
    change_column_null :keys,              :policy_id,     false
    change_column_null :licenses,          :account_id,    false
    change_column_null :licenses,          :policy_id,     false
    change_column_null :licenses,          :product_id,    false
    change_column_null :machines,          :account_id,    false
    change_column_null :machines,          :license_id,    false
    change_column_null :metrics,           :account_id,    false
    change_column_null :policies,          :account_id,    false
    change_column_null :policies,          :product_id,    false
    change_column_null :products,          :account_id,    false
    change_column_null :request_logs,      :account_id,    false
    change_column_null :roles,             :resource_id,   false
    change_column_null :roles,             :resource_type, false
    change_column_null :tokens,            :account_id,    false
    change_column_null :tokens,            :bearer_id,     false
    change_column_null :tokens,            :bearer_type,   false
    change_column_null :users,             :account_id,    false
    change_column_null :webhook_endpoints, :account_id,    false
    change_column_null :webhook_events,    :account_id,    false
  end
end
