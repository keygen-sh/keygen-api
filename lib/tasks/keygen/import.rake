# frozen_string_literal: true

namespace :keygen do
  desc 'Import data into a Keygen account'
  task :import, %i[account_id] => %i[environment] do |_, args|
    require 'io/console'

    account_id = args[:account_id] || ENV.fetch('KEYGEN_ACCOUNT_ID')

    abort 'no stdin' if STDIN.tty?

    ActiveRecord::Base.logger.silence do
      while chunk = STDIN.read(1.kilobyte)
        pp(chunk:)
      end
    end
  end
end
