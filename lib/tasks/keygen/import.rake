# frozen_string_literal: true

namespace :keygen do
  # Usage: rake keygen:import[secret] < encrypted.export
  #        rake keygen:import < unencrypted.export
  desc 'Import data into a Keygen account from STDIN'
  task :import, %i[secret_key] => %i[silence environment] do |_, args|
    secret_key = args[:secret_key]
    account_id = ENV.fetch('KEYGEN_ACCOUNT_ID')

    Keygen::Importer.import(
      from: STDIN,
      account_id:,
      secret_key:,
    )
  end
end
