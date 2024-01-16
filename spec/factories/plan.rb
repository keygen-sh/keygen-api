# frozen_string_literal: true

FactoryBot.define do
  factory :plan do
    initialize_with { new(**attributes) }

    name         { Keygen.ee? ? 'Ent 1' : 'Std 1' }
    price        { Faker::Number.number digits: 4 }
    max_admins   { Faker::Number.between from: 50, to: 5000 }
    max_users    { Faker::Number.between from: 50, to: 5000 }
    max_policies { Faker::Number.between from: 50, to: 5000 }
    max_licenses { Faker::Number.between from: 50, to: 5000 }
    max_products { Faker::Number.between from: 50, to: 5000 }
    max_reqs     { Faker::Number.between from: 50, to: 5000 }

    transient do
      stripe_plan do
        product = StripeHelper.create_product(id: SecureRandom.hex)

        StripeHelper.create_plan(id: SecureRandom.hex, amount: price, trial_period_days: 7, product: product.id)
      end
    end

    after :create do |plan, evaluator|
      next if evaluator.stripe_plan.nil?
      plan.plan_id = evaluator.stripe_plan.id if plan.plan_id.nil?
      plan.save
    end

    trait :std do
      name { "Standard Test" }
    end

    trait :ent do
      name { "Ent Test" }
    end
  end
end
