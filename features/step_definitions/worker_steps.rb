World Rack::Test::Methods

Then /^sidekiq should have (\d+) "([^\"]*)" jobs?$/ do |count, resource|
  worker = "#{resource.singularize.underscore}_worker".classify.constantize
  expect(worker.jobs.size).to eq count.to_i
end

Then /^the (?:account|user) should receive an? "([^\"]*)" email$/ do |mailer|
  Sidekiq::Queues["mailers"].any? do |job|
    job["args"].first["arguments"].include? mailer.underscore
  end
end

Then /^the (?:account|user) should not receive an? "([^\"]*)" email$/ do |mailer|
  Sidekiq::Queues["mailers"].none? do |job|
    job["args"].first["arguments"].include? mailer.underscore
  end
end
