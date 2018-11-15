release: bundle exec rails db:migrate
web: bin/start-pgbouncer bundle exec puma -C config/puma.rb
worker: bin/start-pgbouncer bundle exec sidekiq
whacamole: bundle exec whacamole -c ./config/whacamole.rb
