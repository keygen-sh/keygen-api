#!/usr/bin/env bash
set -e

if [ -f tmp/pids/server.pid ]
then
  rm -f tmp/pids/server.pid
fi

case "$@"
in
setup)
  echo "Running command: bundle exec rails keygen:setup"
  exec bundle exec rails keygen:setup
  ;;
release)
  echo "Running command: bundle exec rails db:migrate"
  exec bundle exec rails db:migrate
  ;;
web)
  echo "Running command: exec rails server -b $BIND -p $PORT"
  exec bundle exec rails server -b "$BIND" -p "$PORT"
  ;;
worker)
  echo "Running command: bundle exec sidekiq"
  exec bundle exec sidekiq
  ;;
*)
  echo "Running command: $@"
  exec "$@"
  ;;
esac
