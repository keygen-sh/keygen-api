# frozen_string_literal: true

namespace :keygen do
  desc 'Import data into a Keygen account'
  task :import, %i[account_id secret_key] => %i[silence environment] do |_, args|
    ActiveRecord::Base.logger.silence do
      account_id = args[:account_id] || ENV.fetch('KEYGEN_ACCOUNT_ID')
      secret_key = args[:secret_key]

      account  = Account.find(account_id)
      importer = Keygen::Import::Importer.new(
        account,
        secret_key:,
      )

      importer.import(from: STDIN)
    end
  end
end
