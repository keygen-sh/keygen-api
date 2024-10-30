# frozen_string_literal: true

FactoryBot.define do
  factory :release_package, aliases: %i[package] do
    initialize_with { new(**attributes.reject { _2 in NIL_ACCOUNT | NIL_ENVIRONMENT }) }

    name { Faker::App.unique.name }
    key  { name.underscore }

    account     { NIL_ACCOUNT }
    environment { NIL_ENVIRONMENT }
    product     { build(:product, account:, environment:) }
    engine      { nil }

    trait :pypi do
      engine { build(:engine, :pypi, account:) }
    end

    trait :tauri do
      engine { build(:engine, :tauri, account:) }
    end

    trait :raw do
      engine { build(:engine, :raw, account:) }
    end

    trait :rubygems do
      engine { build(:engine, :rubygems, account:) }
    end

    trait :npm do
      engine { build(:engine, :npm, account:) }
    end

    trait :licensed do
      product { build(:product, :licensed, account:, environment:) }
    end

    trait :open do
      product { build(:product, :open, account:, environment:) }
    end

    trait :closed do
      product { build(:product, :closed, account:, environment:) }
    end

    trait :in_isolated_environment do
      environment { build(:environment, :isolated, account:) }
    end

    trait :isolated do
      in_isolated_environment
    end

    trait :in_shared_environment do
      environment { build(:environment, :shared, account:) }
    end

    trait :shared do
      in_shared_environment
    end

    trait :in_nil_environment do
      environment { nil }
    end

    trait :global do
      in_nil_environment
    end
  end
end
