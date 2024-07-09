# frozen_string_literal: true

namespace :keygen do
  desc 'Import data into Keygen'
  task :import, %i[secret_key] => %i[silence environment] do |_, args|
    ActiveRecord::Base.logger.silence do
      secret_key = args[:secret_key]

      Keygen::Import.import(
        from: STDIN,
        secret_key:,
      )
    end
  end
end
