# frozen_string_literal: true

namespace :keygen do
  desc 'Export data from a Keygen account'
  task :export, %i[account_id] => %i[environment] do |_, args|
    require 'io/console'

    account_id = args[:account_id] || ENV.fetch('KEYGEN_ACCOUNT_ID')

    ActiveRecord::Base.logger.silence do

    end
  end
end
