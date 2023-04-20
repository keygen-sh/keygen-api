# frozen_string_literal: true

namespace :keygen do
  desc 'List information about Keygen and the environment'
  task about: %i[environment] do
    Keygen::Console.about!
  end
end
