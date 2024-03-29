# frozen_string_literal: true

class ChangeIndicesOnResources < ActiveRecord::Migration[5.0]
  def change
    remove_index :accounts, :name
    add_index :accounts, :id, where: "deleted_at IS NULL"
    add_index :accounts, :name, where: "deleted_at IS NULL"

    remove_index :billings, :customer_id
    remove_index :billings, :subscription_id
    add_index :billings, [:account_id, :id], where: "deleted_at IS NULL"
    add_index :billings, [:customer_id, :account_id], where: "deleted_at IS NULL"
    add_index :billings, [:subscription_id, :account_id], where: "deleted_at IS NULL"

    remove_index :keys, :account_id
    remove_index :keys, :policy_id
    add_index :keys, [:account_id, :id], where: "deleted_at IS NULL"
    add_index :keys, [:policy_id, :account_id], where: "deleted_at IS NULL"

    remove_index :licenses, :account_id
    remove_index :licenses, :policy_id
    remove_index :licenses, :user_id
    remove_index :licenses, :key
    add_index :licenses, [:account_id, :id], where: "deleted_at IS NULL"
    add_index :licenses, [:policy_id, :account_id], where: "deleted_at IS NULL"
    add_index :licenses, [:user_id, :account_id], where: "deleted_at IS NULL"
    add_index :licenses, [:key, :account_id], where: "deleted_at IS NULL"

    remove_index :machines, :account_id
    remove_index :machines, :license_id
    remove_index :machines, :fingerprint
    add_index :machines, [:account_id, :id], where: "deleted_at IS NULL"
    add_index :machines, [:license_id, :account_id], where: "deleted_at IS NULL"
    add_index :machines, [:fingerprint, :account_id], where: "deleted_at IS NULL"

    remove_index :plans, :plan_id
    add_index :plans, :plan_id, where: "deleted_at IS NULL"

    remove_index :policies, :account_id
    remove_index :policies, :product_id
    add_index :policies, [:account_id, :id], where: "deleted_at IS NULL"
    add_index :policies, [:product_id, :account_id], where: "deleted_at IS NULL"

    remove_index :products, :account_id
    add_index :products, [:account_id, :id], where: "deleted_at IS NULL"
    add_index :products, :account_id, where: "deleted_at IS NULL"

    remove_index :roles, [:name, :resource_type, :resource_id]
    remove_index :roles, :name # Duplicate
    add_index :roles, [:name, :resource_type, :resource_id], where: "deleted_at IS NULL"

    remove_index :tokens, :account_id
    remove_index :tokens, [:bearer_id, :bearer_type]
    add_index :tokens, [:account_id, :id], where: "deleted_at IS NULL"
    add_index :tokens, [:bearer_id, :bearer_type, :account_id], where: "deleted_at IS NULL"

    remove_index :users, :account_id
    remove_index :users, :email
    remove_index :users, :password_reset_token
    add_index :users, [:account_id, :id], where: "deleted_at IS NULL"
    add_index :users, [:email, :account_id], where: "deleted_at IS NULL"
    add_index :users, [:password_reset_token, :account_id], where: "deleted_at IS NULL"

    remove_index :webhook_endpoints, :account_id
    add_index :webhook_endpoints, [:account_id, :id], where: "deleted_at IS NULL"

    remove_index :webhook_events, :account_id
    remove_index :webhook_events, :jid
    add_index :webhook_events, [:account_id, :id], where: "deleted_at IS NULL"
    add_index :webhook_events, :jid, where: "deleted_at IS NULL"
  end
end
