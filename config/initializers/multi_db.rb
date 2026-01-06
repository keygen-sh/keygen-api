# frozen_string_literal: true

Rails.application.configure do
  # FIXME(ezekg) these won't work for API-only apps (maybe use Redis to store per-account/token/ip last_write_at?)
  # config.active_record.database_selector         = { delay: 2.seconds }
  # config.active_record.database_resolver         = ActiveRecord::Middleware::DatabaseSelector::Resolver
  # config.active_record.database_resolver_context = ActiveRecord::Middleware::DatabaseSelector::Resolver::Session
end
