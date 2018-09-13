release: bundle exec rails db:migrate
web: bin/start-pgbouncer-stunnel bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq
