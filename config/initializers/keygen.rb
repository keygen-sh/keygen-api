# frozen_string_literal: true

require_dependency Rails.root / 'lib' / 'keygen'

Rails.application.config.to_prepare do
  if Keygen.singleplayer?
    account_id = ENV['KEYGEN_ACCOUNT_ID']
    abort 'environment variable KEYGEN_ACCOUNT_ID is required when running in singleplayer mode' unless
      account_id.present?

    unless Account.exists?(id: account_id)
      abort "account #{account_id} does not exist (run `rake keygen:setup` to create it)"
    end
  end
end
