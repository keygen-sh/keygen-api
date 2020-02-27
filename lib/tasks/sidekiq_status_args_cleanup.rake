# frozen_string_literal: true

desc 'clean up sidekiq-status args'
task sidekiq_status_args_cleanup: :environment do
  redis = Rails.cache.redis

  redis.with do |conn|
    conn.scan_each(match: 'sidekiq:status:*') do |key|
      puts "Clearing args: #{key}"

      conn.hdel key, :args
    end
  end
end