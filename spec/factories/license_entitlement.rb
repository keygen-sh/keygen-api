# frozen_string_literal: true

FactoryBot.define do
  factory :license_entitlement do
    # Prevent duplicates due to cyclic entitlement codes.
    initialize_with do
      LicenseEntitlement.find_by(entitlement_id: entitlement&.id, license_id: license&.id) ||
        new(**attributes.reject { DEFAULT_ENVIRONMENT == _2 })
    end

    account     { nil }
    environment { DEFAULT_ENVIRONMENT }
    entitlement { build(:entitlement, account:, environment:) }
    license     { nil }

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
      after :create do |entitlement|
        entitlement.environment = nil
        entitlement.save!(validate: false)
      end
    end

    trait :global do
      in_nil_environment
    end
  end
end
