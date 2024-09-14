# frozen_string_literal: true

FactoryBot.define do
  factory :release_engine, aliases: %i[engine] do
    initialize_with { new(**attributes) }

    sequence :key, %w[pypi tauri rubygems].cycle

    account { NIL_ACCOUNT }

    trait :pypi do
      name { 'PyPI' }
      key  { 'pypi' }
    end

    trait :tauri do
      name { 'Tauri' }
      key  { 'tairi' }
    end

    trait :rubygems do
      name { 'RubyGems' }
      key  { 'rubygems' }
    end
  end
end
