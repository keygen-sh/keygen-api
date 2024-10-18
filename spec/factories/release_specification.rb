# frozen_string_literal: true

FactoryBot.define do
  factory :release_specification, aliases: %i[spec specification] do
    initialize_with { new(**attributes.reject { _2 in NIL_ACCOUNT | NIL_ENVIRONMENT }) }

    account       { NIL_ACCOUNT }
    environment   { NIL_ENVIRONMENT }
    artifact      { build(:artifact, account:, environment:) }
    release       { artifact.release }
    specification {{ name: Faker::App.name, version: Faker::App.semantic_version }}

    trait :gem do
      artifact      { build(:artifact, :gem, account:, environment:) }
      specification {
        gem = file_fixture('valid.gem').open

        Gem::Package.new(gem).spec.as_json
      }
    end
  end
end
