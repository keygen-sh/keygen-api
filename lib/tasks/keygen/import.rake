# frozen_string_literal: true

namespace :keygen do
  # Usage: rake keygen:import[secret] < encrypted.export
  #        rake keygen:import < unencrypted.export
  desc 'Import data into Keygen'
  task :import, %i[secret_key] => %i[silence environment] do |_, args|
    secret_key = args[:secret_key]

    Keygen::Importer.import(
      from: STDIN,
      secret_key:,
    )
  end
end
