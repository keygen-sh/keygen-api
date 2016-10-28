World Rack::Test::Methods

Then /^sidekiq should have (\d+) "([^\"]*)" jobs?$/ do |count, resource|
  worker = "#{resource.singularize.underscore}_worker".classify.constantize
  expect(worker.jobs.size).to eq count.to_i
end
