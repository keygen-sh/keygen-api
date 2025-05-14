web: RUBYOPT="--yjit --yjit-exec-mem-size=${RUBY_YJIT_EXEC_MEM_SIZE:-64}" bin/start-pgbouncer bundle exec puma -C config/puma.rb
worker: bin/start-pgbouncer bundle exec sidekiq
release: bundle exec rails db:migrate
