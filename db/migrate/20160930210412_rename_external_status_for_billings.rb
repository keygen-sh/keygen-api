# frozen_string_literal: true

class RenameExternalStatusForBillings < ActiveRecord::Migration[5.0]
  def change
    rename_column :billings, :external_status, :external_subscription_status
  end
end
