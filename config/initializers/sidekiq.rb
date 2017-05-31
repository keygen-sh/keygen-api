require 'sidekiq'
require 'sidekiq-status'
require 'sidekiq-cron'

Sidekiq.configure_client do |config|
  config.redis = { size: 1 }

  config.client_middleware do |chain|
    chain.add Sidekiq::Status::ClientMiddleware, expiration: 30.days
  end
end

Sidekiq.configure_server do |config|
  schedule_file = Rails.root.join 'config', 'schedule.yml'

  if File.exist?(schedule_file)
    Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)
  end

  config.server_middleware do |chain|
    chain.add Sidekiq::Status::ServerMiddleware, expiration: 30.days
  end

  config.client_middleware do |chain|
    chain.add Sidekiq::Status::ClientMiddleware, expiration: 30.days
  end
end
