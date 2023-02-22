# frozen_string_literal: true

FactoryBot.define do
  factory :group_permission do
    initialize_with { new(**attributes) }

    permission { nil }
    group      { nil }
  end
end
