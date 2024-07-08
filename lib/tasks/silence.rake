# frozen_string_literal: true

desc 'Disables all logging until environment is loaded'
task :silence do
  ActiveRecord::Base.logger = Rails.logger = Logger.new('/dev/null')
end
