# frozen_string_literal: true

FactoryBot.define do
  factory :permission do
    action { 'test:read' }
  end
end
