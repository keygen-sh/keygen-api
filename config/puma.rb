# frozen_string_literal: true

# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum, this matches the default thread size of Active Record.
max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 2 }.to_i
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

# specifies max acceptable request body size in bytes (returns 413 if exceeded)
if max_request_size = ENV['RAILS_MAX_REQUEST_BODY_SIZE']
  http_content_length_limit max_request_size.to_i
end

# FIXME(ezekg) https://www.heroku.com/blog/pumas-routers-keepalives-ohmy/
enable_keep_alives false

# Ensure our backlog is drained
drain_on_shutdown

# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory. If you use this option
# you need to make sure to reconnect any threads in the `on_worker_boot`
# block.
preload_app!

# Add some logging to understand what Puma is doing
on_worker_boot do
  Keygen.logger.info("[puma] [#{Process.pid}] worker boot event")
end

on_worker_shutdown do
  Keygen.logger.info("[puma] [#{Process.pid}] worker shutdown event")
end

on_refork do
  Keygen.logger.info("[puma] [#{Process.pid}] refork event")
end

on_restart do
  Keygen.logger.info("[puma] [#{Process.pid}] restart event")
end

# Handle low level exceptions from Puma
lowlevel_error_handler do |e|
  Keygen.logger.warn("[puma] [#{Process.pid}] lowlevel error: #{e.message}")
  Keygen.logger.warn(e.backtrace&.join("\n"))

  [
    500,
    {
      "Content-Type" => "application/vnd.api+json; charset=utf-8"
    },
    [{
      errors: [{
        title: "Internal server error",
        detail: "Looks like something went wrong! Our engineers have been notified. If you continue to have problems, please contact support@keygen.sh.",
      }]
    }.to_json]
  ]
end
