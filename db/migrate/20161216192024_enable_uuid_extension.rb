# frozen_string_literal: true

class EnableUuidExtension < ActiveRecord::Migration[5.0]
  def change
    enable_extension "uuid-ossp"
  end
end
