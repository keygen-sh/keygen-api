class BaseMigration < Versionist::Migration
  include Rails.application.routes.url_helpers
end
