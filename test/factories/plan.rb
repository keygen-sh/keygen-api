FactoryGirl.define do
  factory :plan do
    name { Faker::Company.buzzword }
    price { Faker::Number.number 4 }
    max_users { Faker::Number.between 50, 5000 }
    max_policies { Faker::Number.between 50, 5000 }
    max_licenses { Faker::Number.between 50, 5000 }
    max_products { Faker::Number.between 50, 5000 }
    plan_id nil

    transient do
      stripe_plan {
        StripeHelper.create_plan(
          id: SecureRandom.hex,
          trial_period_days: 7,
          amount: price
        )
      }
    end

    after :create do |plan, evaluator|
      plan.plan_id = evaluator.stripe_plan.id if plan.plan_id.nil?
      plan.save
    end
  end
end
