# frozen_string_literal: true

require_dependency Rails.root / 'lib' / 'keygen'

Rails.application.config.to_prepare do
  next if
    Keygen.test? || Keygen.task? # Skip in test and during Rake tasks

  case
  when Keygen.ee?
    unless ENV.key?('KEYGEN_LICENSE_FILE_PATH') || ENV.key?('KEYGEN_LICENSE_FILE')
      abort "Environment variable KEYGEN_LICENSE_FILE_PATH or KEYGEN_LICENSE_FILE is required in EE"
    end

    unless ENV.key?('KEYGEN_LICENSE_KEY')
      abort "Environment variable KEYGEN_LICENSE_KEY is required in EE"
    end
  when Keygen.ce?
    if Keygen.multiplayer?(strict: false)
      abort "Multiplayer mode is only available in EE (use KEYGEN_MODE=singleplayer instead)"
    end
  end

  case
  when Keygen.multiplayer?(strict: false)
    unless Keygen.ee { it.entitled?(:multiplayer) }
      abort "Keygen EE license is missing the multiplayer entitlement (use KEYGEN_MODE=singleplayer instead)"
    end
  when Keygen.singleplayer?
    account_id = ENV['KEYGEN_ACCOUNT_ID']
    unless account_id.present?
      abort 'Environment variable KEYGEN_ACCOUNT_ID is required when running in singleplayer mode'
    end

    unless account_id in UUID_RE
      abort 'Environment variable KEYGEN_ACCOUNT_ID must be a valid UUID'
    end

    unless Account.exists?(id: account_id)
      abort "Account #{account_id} does not exist (run `rake keygen:setup` to create it)"
    end
  end

  unless ENV.key?('KEYGEN_HOST')
    abort "Environment variable KEYGEN_HOST is required"
  end
end
