# frozen_string_literal: true

StatementTimeout.configure do |config|
  config.default_mode = :transaction # for pgbouncer
end
