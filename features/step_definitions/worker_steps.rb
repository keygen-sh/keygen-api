World Rack::Test::Methods

Then /^sidekiq should have (\d+) "([^\"]*)" jobs?$/ do |count, resource|
  worker = "#{resource.singularize.underscore}_worker".classify.constantize
  assert_equal count.to_i, worker.jobs.size
end
