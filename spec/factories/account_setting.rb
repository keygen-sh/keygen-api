# frozen_string_literal: true

FactoryBot.define do
  factory :account_setting, aliases: %i[setting] do
    initialize_with { AccountSetting.find_by(account:, key:) || new(**attributes.reject { _2 in NIL_ACCOUNT }) }

    sequence :key, %w[default_license_permissions default_user_permissions].cycle
    value { %w[license.validate] }

    account { nil }
  end
end
