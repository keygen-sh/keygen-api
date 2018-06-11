begin
  require 'rspec/core/rake_task'

  Rake::Task['test'].clear # Clear default test task

  desc 'run test suite'
  task 'test': %i[
    spec
    cucumber
  ]
rescue LoadError
  # NOTE(ezekg) Wrapping this in a rescue clause so that we can use our
  #             Rakefile in an environment where RSpec is unavailable
  #             e.g. in the production env.
end