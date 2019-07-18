# frozen_string_literal: true

class RolifyCreateRoles < ActiveRecord::Migration
  def change
    create_table(:roles) do |t|
      t.string :name
      t.references :resource, :polymorphic => true

      t.timestamps
    end

    create_table(:tokens_roles, :id => false) do |t|
      t.references :token
      t.references :role
    end

    add_index(:roles, :name)
    add_index(:roles, [ :name, :resource_type, :resource_id ])
    add_index(:tokens_roles, [ :token_id, :role_id ])
  end
end
