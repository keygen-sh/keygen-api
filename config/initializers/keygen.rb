# frozen_string_literal: true

require_dependency Rails.root / 'lib' / 'keygen'

Rails.application.config.to_prepare do
  next if
    Keygen.task?('keygen:setup') # Skip ENV assertions during setup

  if Keygen.singleplayer?
    account_id = ENV['KEYGEN_ACCOUNT_ID']
    unless account_id.present?
      abort 'Environment variable KEYGEN_ACCOUNT_ID is required when running in singleplayer mode'
    end

    unless Account.exists?(id: account_id)
      abort "Account #{account_id} does not exist (run `rake keygen:setup` to create it)"
    end
  end

  if Keygen.ee?
    unless ENV.key?('KEYGEN_LICENSE_FILE_PATH') || ENV.key?('KEYGEN_LICENSE_FILE')
      abort "Environment variable KEYGEN_LICENSE_FILE_PATH or KEYGEN_LICENSE_FILE is required in EE"
    end

    unless ENV.key?('KEYGEN_LICENSE_KEY')
      abort "Environment variable KEYGEN_LICENSE_KEY is required in EE"
    end
  end
end
