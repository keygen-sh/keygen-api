# frozen_string_literal: true

class AddAssociationIndices < ActiveRecord::Migration[5.0]
  def up
    add_index :accounts, :plan_id, where: "deleted_at IS NULL"
    add_index :billings, :account_id, where: "deleted_at IS NULL"
    add_index :keys, :policy_id, where: "deleted_at IS NULL"
    add_index :keys, :account_id, where: "deleted_at IS NULL"
    add_index :licenses, :user_id, where: "deleted_at IS NULL"
    add_index :licenses, :policy_id, where: "deleted_at IS NULL"
    add_index :licenses, :account_id, where: "deleted_at IS NULL"
    add_index :machines, :account_id, where: "deleted_at IS NULL"
    add_index :machines, :license_id, where: "deleted_at IS NULL"
    add_index :policies, :product_id, where: "deleted_at IS NULL"
    add_index :policies, :account_id, where: "deleted_at IS NULL"
    add_index :products, :account_id, where: "deleted_at IS NULL"
    add_index :receipts, :billing_id, where: "deleted_at IS NULL"
    add_index :roles, :resource_id, where: "deleted_at IS NULL"
    add_index :tokens, :bearer_id, where: "deleted_at IS NULL"
    add_index :tokens, :account_id, where: "deleted_at IS NULL"
    add_index :users, :account_id, where: "deleted_at IS NULL"
    add_index :webhook_endpoints, :account_id, where: "deleted_at IS NULL"
    add_index :webhook_events, :account_id, where: "deleted_at IS NULL"
  end
end
