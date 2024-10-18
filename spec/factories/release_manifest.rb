# frozen_string_literal: true

FactoryBot.define do
  factory :release_manifest, aliases: %i[manifest] do
    initialize_with { new(**attributes) }

    account { NIL_ACCOUNT }

    trait :gemspec do
      # see: https://docs.ruby-lang.org/en/master/Gem/Specification.html
      metadata {{
        name: Faker::App.name,
        summary: Faker::App.description,
        version: Faker::App.semantic_version,
      }}
    end
  end
end
