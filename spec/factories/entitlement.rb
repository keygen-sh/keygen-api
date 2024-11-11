# frozen_string_literal: true

FactoryBot.define do
  factory :entitlement do
    # Prevent duplicates due to cyclic entitlement codes below. Attempting
    # to insert duplicate codes would fail, and this prevents that.
    initialize_with { Entitlement.find_by(account:, code:) || new(**attributes.reject { _2 in NIL_ACCOUNT | NIL_ENVIRONMENT }) }

    account     { NIL_ACCOUNT }
    environment { NIL_ENVIRONMENT }

    # Our entitlement codes cycle in sets of 10, so we can do things like
    # constrain a release with 10 entitlements via the :with_constraints
    # trait, and subsequently entitle a license with the same 10
    # entitlements via the :with_entitlements trait.
    sequence :code, %w[ALPHA BRAVO CHARLIE DELTA ECHO FOXTROT GOLF HOTEL INDIA JULIETT].cycle
    name { code.humanize }

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
