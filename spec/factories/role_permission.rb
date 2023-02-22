# frozen_string_literal: true

FactoryBot.define do
  factory :role_permission do
    initialize_with { new(**attributes) }

    permission { nil }
    role       { nil }
  end
end
