# frozen_string_literal: true

namespace :keygen do
  desc 'Export data from Keygen to STDOUT'
  task :export, %i[secret_key] => %i[silence environment] do |_, args|
    ActiveRecord::Base.logger.silence do
      secret_key = args[:secret_key]
      account_id = ENV.fetch('KEYGEN_ACCOUNT_ID')
      account    = Account.find(account_id)

      Keygen::Export.export(
        account,
        to: STDOUT,
        secret_key:,
      )
    end
  end
end
