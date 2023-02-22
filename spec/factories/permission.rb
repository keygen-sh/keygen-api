# frozen_string_literal: true

FactoryBot.define do
  factory :permission do
    initialize_with { new(**attributes) }

    action { 'test:read' }
  end
end
