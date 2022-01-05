module RequestCounter
  extend ActiveSupport::Concern

  REQUEST_COUNT_IGNORED_ORIGINS = %w[https://app.keygen.sh https://dist.keygen.sh].freeze

  included do
    around_action :count_request!

    private

    def count_request!
      yield
    ensure
      increment_request_count
    end

    def request_count_cache_key
      Current.account.daily_request_count_cache_key
    end

    def count_request?
      return false if
        REQUEST_COUNT_IGNORED_ORIGINS.include?(request.headers['Origin'])

      Current.account.present?
    end

    def increment_request_count
      return unless
        count_request?

      Rails.cache.increment(request_count_cache_key, 1, expires_in: 1.day)
    end
  end
end
