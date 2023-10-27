class BaseMigration < RequestMigrations::Migration
  include Rails.application.routes.url_helpers

  def self.json?(request)   = request.format == :jsonapi || request.format == :json
  def self.binary?(request) = request.format == :binary
  def self.html?(request)   = request.format == :html
end
