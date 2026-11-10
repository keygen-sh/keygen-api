# frozen_string_literal: true

class AddCanceledAtToLicenses < ActiveRecord::Migration[8.1]
  verbose!

  def change
    add_column :licenses, :canceled_at, :datetime, null: true, if_not_exists: true
  end
end
