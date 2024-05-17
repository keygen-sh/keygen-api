# frozen_string_literal: true

FactoryBot.define do
  factory :release_engine, aliases: %i[engine] do
    initialize_with { new(**attributes.reject { NIL_ACCOUNT == _2 }) }

    sequence :key, %w[pypi tauri].cycle

    account { NIL_ACCOUNT }

    trait :pypi do
      name { 'PyPI' }
      key  { 'pypi' }
    end

    trait :tauri do
      name { 'Tauri' }
      key  { 'tairi' }
    end
  end
end
