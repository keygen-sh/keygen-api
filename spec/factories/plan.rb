# frozen_string_literal: true

FactoryBot.define do
  factory :plan do
    name { Faker::Company.buzzword }
    price { Faker::Number.number 4 }
    max_admins { Faker::Number.between 50, 5000 }
    max_users { Faker::Number.between 50, 5000 }
    max_policies { Faker::Number.between 50, 5000 }
    max_licenses { Faker::Number.between 50, 5000 }
    max_products { Faker::Number.between 50, 5000 }
    max_reqs { Faker::Number.between 50, 5000 }

    transient do
      stripe_plan do
        StripeHelper.create_plan(id: SecureRandom.hex, amount: price, trial_period_days: 7) rescue nil
      end
    end

    after :create do |plan, evaluator|
      next if evaluator.stripe_plan.nil?
      plan.plan_id = evaluator.stripe_plan.id if plan.plan_id.nil?
      plan.save
    end
  end
end
