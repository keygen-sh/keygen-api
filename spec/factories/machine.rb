# frozen_string_literal: true

FactoryGirl.define do
  factory :machine do
    fingerprint { SecureRandom.hex(12).upcase.scan(/.{2}/).join ":" }
    name { Faker::Company.buzzword }

    account nil
    license nil

    after :build do |machine, evaluator|
      account = evaluator.account.presence || create(:account)
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
