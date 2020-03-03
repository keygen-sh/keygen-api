release: bundle exec rails db:migrate
web: bin/start-pgbouncer bundle exec falcon serve -b http://0.0.0.0:${PORT:-3000}
worker: bin/start-pgbouncer bundle exec sidekiq
whacamole: bundle exec whacamole -c ./config/whacamole.rb
