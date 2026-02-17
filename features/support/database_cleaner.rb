# frozen_string_literal: true

require 'database_cleaner'

# see: https://github.com/DatabaseCleaner/database_cleaner-active_record/issues/86
module DatabaseCleaner
  module PristineConnectionExtension
    def clean
      @connection = nil

      super
    end
  end

  ActiveRecord::Truncation.prepend PristineConnectionExtension
end
