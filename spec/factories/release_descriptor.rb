# frozen_string_literal: true

FactoryBot.define do
  factory :release_descriptor, aliases: %i[descriptor] do
    initialize_with { new(**attributes.reject { _2 in NIL_ACCOUNT | NIL_ENVIRONMENT }) }

    account     { NIL_ACCOUNT }
    environment { NIL_ENVIRONMENT }
    artifact    { build(:artifact, account:, environment:) }
    release     { artifact.release }

    content_path   { Faker::File.file_name }
    content_type   { Faker::File.mime_type }
    content_length { rand(1.kilobyte..512.megabytes) }
    content_digest { Random.hex(32) }

    trait :licensed do
      artifact { build(:artifact, :licensed, account:, environment:) }
    end

    trait :open do
      artifact { build(:artifact, :open, account:, environment:) }
    end

    trait :closed do
      artifact { build(:artifact, :closed, account:, environment:) }
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
