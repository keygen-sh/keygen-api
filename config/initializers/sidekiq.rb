require 'sidekiq'
require 'sidekiq-status'

Sidekiq.configure_client do |config|
  config.client_middleware do |chain|
    chain.add Sidekiq::Status::ClientMiddleware, expiration: 30.days
  end
end

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add Sidekiq::Status::ServerMiddleware, expiration: 30.days
  end
  config.client_middleware do |chain|
    chain.add Sidekiq::Status::ClientMiddleware, expiration: 30.days
  end
end
