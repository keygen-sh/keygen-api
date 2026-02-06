# frozen_string_literal: true

World Rack::Test::Methods

Then /^sidekiq should (?:have|process) (\d+) "([^\"]*)" jobs?(?: queued in ([.\d]+ \w+))?$/ do |expected_count, worker_name, queued_at|
  worker_name =
    case worker_name
    when "request-log"
      "request_log_worker2"
    when "event-log"
      "event_log_worker2"
    when "event-notification"
      "event_notification_worker"
    when "machine-heartbeat"
      "machine_heartbeat_worker"
    when "process-heartbeat"
      "process_heartbeat_worker"
    else
      "#{worker_name.singularize.underscore}_worker"
    end

  # Skip request and event log assertions for CE
  next if
    Keygen.ce? && worker_name.in?(%w[request_log_worker2 event_log_worker2])

  # Drain certain queues before count
  case worker_name
  when "request_log_worker2",
       "event_log_worker2"
    PerformBulk::Processor.drain # process and queue bulk jobs
    PerformBulk::Runner.drain
  when "webhook_worker"
    CreateWebhookEventsWorker2.drain
  end

  # Count queued jobs
  worker_class = worker_name.classify.constantize
  worker_count = worker_class.jobs.size

  expect(worker_count).to eq expected_count.to_i

  # Drain certain queues after count
  case worker_name
  when "initialize_billing_worker"
    InitializeBillingWorker.drain
  when "event_notification_worker"
    EventNotificationWorker.drain
  when "touch_license_worker"
    TouchLicenseWorker.drain
  end

  # Future queueing
  next unless
    queued_at.present?

  job  = worker_class.jobs.last
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

Then /^the (?:account|user) should receive an? "([^\"]*)" email$/ do |mailer|
  received_any = enqueued_jobs_with(queue: 'mailers').any? do |job|
    job['arguments'].include? mailer.underscore.parameterize(separator: '_')
  end
  expect(received_any).to be true
end

Then /^the (?:account|user) should not receive an? "([^\"]*)" email$/ do |mailer|
  received_any = enqueued_jobs_with(queue: 'mailers').any? do |job|
    job['arguments'].include? mailer.underscore.parameterize(separator: '_')
  end
  expect(received_any).to be false
end
