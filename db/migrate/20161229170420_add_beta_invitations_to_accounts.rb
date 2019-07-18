# frozen_string_literal: true

class AddBetaInvitationsToAccounts < ActiveRecord::Migration[5.0]
  def change
    add_column :accounts, :invite_state, :string
    add_column :accounts, :invite_token, :string
    add_column :accounts, :invite_sent_at, :timestamp
  end
end
