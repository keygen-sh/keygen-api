# frozen_string_literal: true

World Rack::Test::Methods

Then /^sidekiq should have (\d+) "([^\"]*)" jobs?(?: queued in ([.\d]+ \w+))?$/ do |count, resource, queued_at|
  case resource
  when "webhook"
    CreateWebhookEventsWorker.drain # Make sure our webhooks are created
  when "metric"
    resource = "record_metric" # We renamed this worker
  when "request-log"
    resource = "request_log"
  when "heartbeat"
    resource = "machine_heartbeat"
  end

  worker = "#{resource.singularize.underscore}_worker"

  expect(worker.classify.constantize.jobs.size).to eq count.to_i

  if queued_at.present?
    job = worker.classify.constantize.jobs.last
    n, m = queued_at.split ' '

    dt = n.to_f.send(m)
    t1 = job['at']
    t2 = dt.from_now.to_f

    case m
    when 'seconds', 'minutes'
      expect(t1).to be_within(3.seconds).of t2
    else
      expect(t1).to be_within(1.minute).of t2
    end
  end
end

Then /^the (?:account|user) should receive an? "([^\"]*)" email$/ do |mailer|
  received_any = Sidekiq::Queues["mailers"].any? do |job|
    job["args"].first["arguments"].include? mailer.parameterize(separator: "_")
  end
  expect(received_any).to be true
end

Then /^the (?:account|user) should not receive an? "([^\"]*)" email$/ do |mailer|
  received_any = Sidekiq::Queues["mailers"].any? do |job|
    job["args"].first["arguments"].include? mailer.parameterize(separator: "_")
  end
  expect(received_any).to be false
end
