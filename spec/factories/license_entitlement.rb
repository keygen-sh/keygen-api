# frozen_string_literal: true

FactoryBot.define do
  factory :license_entitlement do
    # Prevent duplicates due to cyclic entitlement codes.
    initialize_with do
      LicenseEntitlement.find_by(entitlement_id: entitlement&.id, license_id: license&.id) ||
        new(**attributes.reject { _2 in NIL_ACCOUNT | NIL_ENVIRONMENT })
    end

    account     { NIL_ACCOUNT }
    environment { NIL_ENVIRONMENT }
    entitlement { build(:entitlement, account:, environment:) }
    license     { build(:license, account:, environment:) }

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
