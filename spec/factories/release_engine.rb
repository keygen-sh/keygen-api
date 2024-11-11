# frozen_string_literal: true

FactoryBot.define do
  factory :release_engine, aliases: %i[engine] do
    initialize_with { new(**attributes.reject { NIL_ACCOUNT == _2 }) }

    sequence :key, %w[pypi tauri raw].cycle

    account { NIL_ACCOUNT }

    trait :pypi do
      name { 'PyPI' }
      key  { 'pypi' }
    end

    trait :tauri do
      name { 'Tauri' }
      key  { 'tairi' }
    end

    trait :raw do
      name { 'Raw' }
      key  { 'raw' }
    end

    trait :rubygems do
      name { 'Rubygems' }
      key  { 'rubygems' }
    end

    trait :npm do
      name { 'npm' }
      key  { 'npm' }
    end

    trait :oci do
      name { 'oci' }
      key  { 'oci' }
    end
  end
end
