release: bundle exec rails db:migrate
web: RUBYOPT="--yjit --yjit-exec-mem-size=${RUBY_YJIT_EXEC_MEM_SIZE:-64}" bin/start-pgbouncer bundle exec puma -C config/puma.rb
worker: bin/start-pgbouncer bundle exec sidekiq
whacamole: bundle exec whacamole -c ./config/whacamole.rb
