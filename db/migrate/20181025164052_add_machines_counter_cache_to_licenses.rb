# frozen_string_literal: true

class AddMachinesCounterCacheToLicenses < ActiveRecord::Migration[5.0]
  def change
    add_column :licenses, :machines_count, :integer, default: 0

    License.find_each do |license|
      License.reset_counters license.id, :machines
    end
  end
end
