# frozen_string_literal: true

begin
  require 'rspec/core/rake_task'
  require 'parallel_tests'

  Rake::Task['test'].clear # Clear default test task

  desc 'run test suite'
  task test: %i[
    test:environment
    log:clear
    test:rspec
    test:cucumber
  ]

  namespace :test do
    task :environment do
      # We want to make sure that we stay within Redis' default 16 database limit,
      # without using database /0 (our potential development database).
      #
      # Thus, we need to keep this in the range of 1..14 for /1../15.
      ENV['PARALLEL_TEST_PROCESSORS'] = Parallel.processor_count.clamp(1, 14)
                                                                .to_s

      # We don't want to interfere with our development/test databases.
      ENV['PARALLEL_TEST_FIRST_IS_1'] = '1'

      # Ensure we always have a test number set (various parts of our suite rely on it).
      #
      # See: https://github.com/grosser/parallel_tests/issues/505
      ENV['TEST_ENV_NUMBER'] ||= '1'

      # Ensure we're always in the test environment.
      ENV['RAILS_ENV'] = Rails.env = 'test'
    end

    desc 'setup test suite'
    task setup: %i[
      test:environment
      log:clear
      parallel:setup
      parallel:seed
    ]

    desc 'run rspec test suite'
    task :rspec, %i[pattern] => %i[test:environment log:clear] do |_, args|
      pattern = args[:pattern]

      if pattern&.match?(/(\[\d)?(:\d)+\]?$/) # parallel_tests doesn't support line numbers/example IDs
        rspec = Rake::Task['spec']

        # FIXME(ezekg) Remove [ from GLOB_PATTERN so spec/foo_spec.rb[1:2:3:4] patterns are supported
        #              See: https://github.com/rspec/rspec-core/issues/3062
        Rake::FileList::GLOB_PATTERN = %r{[*?\{]}

        ENV['SPEC'] = pattern.shellescape

        rspec.invoke
      else
        Rake::Task['parallel:spec'].invoke(nil, pattern)
      end
    end

    desc 'run cucumber test suite'
    task :cucumber, %i[pattern] => %i[test:environment log:clear] do |_, args|
      pattern = args[:pattern]

      if pattern&.match?(/:\d+$/) # parallel_tests doesn't support line numbers
        cucumber = Rake::Task['cucumber']

        ENV['FEATURE'] = pattern.shellescape

        cucumber.invoke
      else
        Rake::Task['parallel:features'].invoke(nil, pattern)
      end
    end
  end
rescue LoadError
  # NOTE(ezekg) Wrapping this in a rescue clause so that we can use our
  #             Rakefile in an environment where RSpec is unavailable
  #             e.g. in the production env.
end
