FactoryGirl.define do
  factory :plan do
    name { Faker::Company.buzzword }
    price { Faker::Number.number 4 }
    max_users { Faker::Number.between 50, 5000 }
    max_policies { Faker::Number.between 50, 5000 }
    max_licenses { Faker::Number.between 50, 5000 }
    max_products { Faker::Number.between 50, 5000 }

    after :create do |plan|
      stripe_plan = StripeHelper.create_plan id: SecureRandom.hex, amount: plan.price, trial_period_days: 7

      plan.update plan_id: stripe_plan.id
    end
  end
end
