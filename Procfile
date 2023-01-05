release: bundle exec rails db:migrate
web: RUBYOPT="--yjit-exec-mem-size=${RUBY_YJIT_EXEC_MEM_SIZE:-128}" bin/start-pgbouncer bundle exec puma -C config/puma.rb
worker: RUBYOPT="--yjit-exec-mem-size=${RUBY_YJIT_EXEC_MEM_SIZE:-128}" bin/start-pgbouncer bundle exec sidekiq
whacamole: bundle exec whacamole -c ./config/whacamole.rb
