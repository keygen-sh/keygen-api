# frozen_string_literal: true

FactoryBot.define do
  factory :release_engine, aliases: %i[engine] do
    initialize_with { new(**attributes) }

    name { Faker::App.unique.name }
    key  { name.underscore }
  end
end
