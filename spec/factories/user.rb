# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    first_name { Faker::Name.name }
    last_name { Faker::Name.name }
    email { [SecureRandom.hex(4), Faker::Internet.safe_email].join('') }
    password { "password" }

    account { nil }

    after :build do |user, evaluator|
      user.account ||= evaluator.account.presence
    end

    after :create do |user|
      user.role = create :role, :user, resource: user
    end

    factory :admin do
      after :create do |admin|
        admin.role = create :role, :admin, resource: admin
      end
    end

    factory :developer do
      after :create do |dev|
        dev.role = create :role, :developer, resource: dev
      end
    end

    factory :support_agent do
      after :create do |agent|
        agent.role = create :role, :support_agent, resource: agent
      end
    end

    factory :sales_agent do
      after :create do |agent|
        agent.role = create :role, :sales_agent, resource: agent
      end
    end

    factory :read_only do
      after :create do |user|
        user.role = create :role, :read_only, resource: user
      end
    end
  end
end
