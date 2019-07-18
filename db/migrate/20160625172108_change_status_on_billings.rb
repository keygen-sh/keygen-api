# frozen_string_literal: true

class ChangeStatusOnBillings < ActiveRecord::Migration[5.0]
  def change
    rename_column :billings, :status, :external_status
  end
end
