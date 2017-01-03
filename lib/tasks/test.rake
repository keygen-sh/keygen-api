begin
  require 'rspec/core/rake_task'

  Rake::Task[:test].clear
  task test: [:spec, :cucumber]
rescue LoadError
end
