#!/usr/bin/env ruby
# frozen_string_literal: true

# FIXME(ezekg) Remove once we upgrade to Rails 6 which supports `expire` on Redis `incr`
desc 'clean up daily limit keyspace'
task daily_limits_cleanup: :environment do
  redis = Rails.cache.redis
  t1 = Account.daily_request_count_cache_key_ts.to_i

  puts "Current timestamp: #{t1}"

  redis.with do |conn|
    conn.scan_each(match: 'req:limits:daily:*') do |key|
      t2 = key.split(':').last.to_i
      if t2 >= t1
        puts "Skipping: #{key}"

        next
      end

      puts "Clearing: #{key}"

      conn.unlink key
    end
  end
end