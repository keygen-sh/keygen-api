# frozen_string_literal: true

FactoryBot.define do
  factory :token_permission do
    permission { nil }
    token { nil }
  end
end
