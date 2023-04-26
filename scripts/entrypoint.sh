#!/usr/bin/env bash
set -e

if [ -f tmp/pids/server.pid ]
then
  rm -f tmp/pids/server.pid
fi

case "$@"
in
release)
  echo "Running command: bundle exec rails db:migrate"
  bundle exec rails db:migrate
  ;;
web)
  echo "Running command: exec rails server -b $BIND -p $PORT"
  bundle exec rails server -b "$BIND" -p "$PORT"
  ;;
worker)
  echo "Running command: bundle exec sidekiq"
  bundle exec sidekiq
  ;;
*)
  echo "Running command: $@"
  exec "$@"
  ;;
esac
