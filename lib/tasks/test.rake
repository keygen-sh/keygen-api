# frozen_string_literal: true

begin
  require 'rspec/core/rake_task'
  require 'parallel_tests'

  Rake::Task['test'].clear # Clear default test task

  desc 'run test suite'
  task test: %i[
    test:rspec
    test:cucumber
  ]

  namespace :test do
    task :environment do
      # We want to make sure that we stay within Redis' default 16 database limit,
      # without using database /0 (our potential development database).
      #
      # Thus, we need to keep this in the range of 1..14 for /1../15.
      ENV['PARALLEL_TEST_PROCESSORS'] = (Parallel.processor_count - 2).clamp(1, 14)
                                                                      .to_s

      # We don't want to interfere with our development/test databases.
      ENV['PARALLEL_TEST_FIRST_IS_1'] = '1'

      # Ensure we're always in the test environment.
      Rails.env = 'test'
    end

    desc 'run rspec test suite'
    task rspec: %i[
      test:environment
      log:clear
      parallel:spec
    ]

    desc 'run cucumber test suite'
    task cucumber: %i[
      test:environment
      log:clear
      parallel:features
    ]
  end
rescue LoadError
  # NOTE(ezekg) Wrapping this in a rescue clause so that we can use our
  #             Rakefile in an environment where RSpec is unavailable
  #             e.g. in the production env.
end
