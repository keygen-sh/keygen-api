# frozen_string_literal: true

FactoryBot.define do
  factory :token_permission do
    initialize_with { new(**attributes) }

    permission { nil }
    token      { nil }
  end
end
