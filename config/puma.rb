# frozen_string_literal: true

# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum, this matches the default thread size of Active Record.
max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }.to_i
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }.to_i
threads min_threads_count, max_threads_count

# Specifies the `port` that Puma will listen on to receive requests, default is 3000.
port ENV.fetch("PORT") { 3000 }.to_i

# Specifies the `environment` that Puma will run in.
environment ENV.fetch("RAILS_ENV") { "development" }

# Specifies the number of `workers` to boot in clustered mode.
# Workers are forked webserver processes. If using threads and workers together
# the concurrency of the application would be max `threads` * `workers`.
# Workers do not work on JRuby or Windows (both of which do not support
# processes).
workers ENV.fetch("WEB_CONCURRENCY") { 2 }.to_i

# Specifies connection keep-alive/idle timeout
persistent_timeout ENV.fetch("RAILS_KEEP_ALIVE_TIMEOUT") { 20 }.to_i

# https://github.com/puma/puma/blob/de632261ac45d7dd85230c83f6af6dd720f1cbd9/5.0-Upgrade.md#lower-latency-better-throughput
wait_for_less_busy_worker ENV.fetch("RAILS_WAIT_FOR_LESS_BUSY_WORKERS") { 0.005 }.to_f

# https://github.com/puma/puma/blob/de632261ac45d7dd85230c83f6af6dd720f1cbd9/5.0-Upgrade.md#better-memory-usage
nakayoshi_fork

# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory. If you use this option
# you need to make sure to reconnect any threads in the `on_worker_boot`
# block.
preload_app!

# The code in the `on_worker_boot` will be called if you are using
# clustered mode by specifying a number of `workers`. After each worker
# process is booted this block will be run, if you are using `preload_app!`
# option you will want to use this block to reconnect to any threads
# or connections that may have been created at application boot, Ruby
# cannot share connections between processes.
on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end