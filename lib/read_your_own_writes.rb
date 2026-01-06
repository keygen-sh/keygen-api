# frozen_string_literal: true

module ReadYourOwnWrites
  # Redis-based resolver context for read-your-own-writes in API-only apps.
  #
  # Unlike the default Session resolver which uses cookies, this resolver
  # stores the last write timestamp in Redis, keyed by a composite client
  # identifier from Current attributes (account + bearer + token + IP).
  #
  # This ensures that after a write, subsequent reads from the same client
  # are routed to the primary database until the replica catches up.
  #
  # @example Configuration
  #   config.active_record.database_resolver_context = ReadYourOwnWrites::RedisContext
  #
  class RedisContext
    REDIS_KEY_PREFIX = 'ryow'
    REDIS_TTL = 30.seconds

    class << self
      def call(request) = new(request)

      def convert_time_to_timestamp(t)
        t.to_i * 1000 + t.usec / 1000
      end

      def convert_timestamp_to_time(t)
        t ? Time.at(t / 1000, (t % 1000) * 1000) : Time.at(0)
      end
    end

    attr_reader :request

    def initialize(request)
      @request = request
    end

    def last_write_timestamp
      t = redis { it.get(redis_key) }&.to_i

      self.class.convert_timestamp_to_time(t)
    end

    def update_last_write_timestamp
      t = self.class.convert_time_to_timestamp(Time.now)

      redis { it.set(redis_key, t, ex: REDIS_TTL) }
    end

    def save(response)
      # No-op: state is stored in Redis, not the response
    end

    private

    def redis_key = "#{REDIS_KEY_PREFIX}:#{client_id}"
    def redis(&)
      Rails.cache.redis.then(&)
    rescue Redis::BaseError, Errno::ECONNREFUSED
      # If Redis is unavailable, fail open (allow reads from replica)
      nil
    end

    def client_id
      # Combine all available identifiers for a unique client fingerprint.
      # This ensures only the specific client that performed a write is
      # routed to primary, not all clients sharing the same account.
      @client_id ||= begin
        # FIXME(ezekg) request.params[:account_id] isn't available here since
        #              afaict our routes haven't been defined yet
        #
        # TODO(ezekg) would be best to resolve the account and use ID
        account_id  = request.path[/^\/v\d+\/accounts\/([^\/]+)\//, 1] || ''
        identifiers = [
          account_id,
          request.authorization,
          request.remote_ip,
        ]

        Digest::SHA2.hexdigest(identifiers.join(':'))
      end
    end
  end
end
