# frozen_string_literal: true

require_dependency Rails.root / 'lib' / 'read_your_own_writes'

Rails.application.configure do
  config.active_record.database_selector         = { delay: 2.seconds }
  config.active_record.database_resolver         = ActiveRecord::Middleware::DatabaseSelector::Resolver
  config.active_record.database_resolver_context = ReadYourOwnWrites::RedisContext
end
