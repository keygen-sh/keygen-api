# frozen_string_literal: true

begin
  require 'rspec/core/rake_task'
  require 'parallel_tests'

  Rake::Task['test'].clear # Clear default test task

  # We want to make sure that we stay within Redis' default 16 database limit,
  # without using database /0 (our potential development database).
  #
  # Thus, we need to keep this in the range of 1..14 for /1../15.
  ENV['PARALLEL_TEST_PROCESSORS'] = (Parallel.processor_count - 2).clamp(1, 14)
                                                                  .to_s

  # We don't want to interfere with our development/test databases.
  ENV['PARALLEL_TEST_FIRST_IS_1'] = '1'

  desc 'run test suite'
  task 'test': %i[
    log:clear
    parallel:spec
    parallel:features
  ]
rescue LoadError
  # NOTE(ezekg) Wrapping this in a rescue clause so that we can use our
  #             Rakefile in an environment where RSpec is unavailable
  #             e.g. in the production env.
end
