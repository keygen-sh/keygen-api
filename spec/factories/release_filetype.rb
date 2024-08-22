# frozen_string_literal: true

FactoryBot.define do
  factory :release_filetype, aliases: %i[filetype] do
    initialize_with { new(**attributes.reject { NIL_ACCOUNT == _2 }) }

    sequence :key, %w[dmg exe zip tar.gz appimage].cycle

    account { NIL_ACCOUNT }
  end
end
