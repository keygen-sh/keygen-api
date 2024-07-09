# frozen_string_literal: true

namespace :keygen do
  desc 'Export data from a Keygen account'
  task :export, %i[account_id secret_key] => %i[silence environment] do |_, args|
    ActiveRecord::Base.logger.silence do
      account_id = args[:account_id] || ENV.fetch('KEYGEN_ACCOUNT_ID')
      secret_key = args[:secret_key]
      account    = Account.find(account_id)

      Keygen::Export.export(
        account,
        to: STDOUT,
        secret_key:,
      )
    end
  end
end
