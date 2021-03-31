# frozen_string_literal: true

FactoryGirl.define do
  factory :machine do
    fingerprint { SecureRandom.hex(12).upcase.scan(/.{2}/).join ":" }
    name { Faker::Company.buzzword }

    association :account
    association :license

    after :build do |machine, evaluator|
      account = evaluator.account or create :account
      license =
        case
        when evaluator.license.present?
          evaluator.license
        else
          create :license, account: account
        end

      machine.assign_attributes(
        account: account,
        license: license
      )
    end
  end
end
