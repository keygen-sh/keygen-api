# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    initialize_with { new(**attributes.reject { _2 in NIL_ACCOUNT | NIL_ENVIRONMENT }) }

    first_name { Faker::Name.first_name }
    last_name  { Faker::Name.last_name }
    email      { SecureRandom.hex(4) + Faker::Internet.safe_email }
    password   { 'password' }

    account     { NIL_ACCOUNT }
    environment { NIL_ENVIRONMENT }

    factory :admin do
      role { build(:role, :admin) }
    end

    factory :developer do
      role { build(:role, :developer) }
    end

    factory :support_agent do
      role { build(:role, :support_agent) }
    end

    factory :sales_agent do
      role { build(:role, :sales_agent) }
    end

    factory :read_only do
      role { build(:role, :read_only) }
    end

    trait :admin do
      role { build(:role, :admin) }
    end

    trait :read_only do
      role { build(:role, :read_only) }
    end

    trait :passwordless do
      password { nil }
    end

    trait :with_owned_licenses do
      after :create do |user|
        create_list(:license, 3, account: user.account, environment: user.environment, owner: user)
      end
    end

    trait :with_owned_license do
      after :create do |user|
        create(:license, account: user.account, environment: user.environment, owner: user)
      end
    end

    trait :with_user_licenses do
      after :create do |user|
        create_list(:license_user, 3, account: user.account, environment: user.environment, user:)
      end
    end

    trait :with_licenses do
      with_user_licenses
      with_owned_license
    end

    trait :with_expired_licenses do
      after :create do |user|
        create_list(:license, 3, :expired, account: user.account, environment: user.environment, owner: user)
      end
    end

    trait :with_entitled_licenses do
      after :create do |user|
        licenses = create_list(:license, 3, account: user.account, environment: user.environment, owner: user)

        licenses.each do |license|
          create_list(:license_entitlement, 10, account: license.account, environment: license.environment, license:)
        end
      end
    end

    trait :with_grouped_licenses do
      after :create do |user|
        create_list(:license, 3, :with_group, account: user.account, environment: user.environment, owner: user)
      end
    end

    trait :with_group do
      group { build(:group, account:, environment:) }
    end

    trait :with_root_permissions do
      after :create do |user|
        user.update!(permissions: Permission::ALL_PERMISSIONS)
      end
    end

    trait :with_no_permissions do
      after :create do |user|
        user.update!(permissions: [])
      end
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
