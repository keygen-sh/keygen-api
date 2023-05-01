# frozen_string_literal: true

namespace :db do
  namespace :seed do
    desc 'Loads the seed data from db/seeds/development.rb'
    task development: %i[environment] do
      abort "Rails environment must be development (got #{Rails.env})" unless
        Rails.env.development?

      load Rails.root / 'db' / 'seeds' / 'development.rb'
    end
  end
end
