FactoryGirl.define do
  factory :product do
    name { Faker::App.name }
    platforms {
      [
        Faker::Hacker.abbreviation,
        Faker::Hacker.abbreviation,
        Faker::Hacker.abbreviation
      ]
    }

    account

    after :create do |product|
      create :role, :product, resource: product
      create :token, bearer: product
    end
  end
end
