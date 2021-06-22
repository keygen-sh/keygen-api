# frozen_string_literal: true

FactoryGirl.define do
  factory :release do
    name { Faker::App.name }
    filename { "#{name}-#{version}.#{filetype.key}" }
    filesize { Faker::Number.between(from: 0, to: 1.gigabyte.to_i) }

    account nil
    product nil
    platform nil
    filetype nil
    channel nil
  end
end
