class BaseMigration < RequestMigrations::Migration
  include Rails.application.routes.url_helpers
end
