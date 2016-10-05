require 'cucumber/rails'
require 'sidekiq/testing'
require 'faker'

ActionController::Base.allow_rescue = false

World FactoryGirl::Syntax::Methods

DatabaseCleaner.strategy = :transaction

Sidekiq::Testing.fake!

# Monkey patch sidekiq-status
module Sidekiq::Status
  module Testing
    class << self

      def statii(jid)
        @statii      ||= {}
        @statii[jid] ||= []
      end

      def push_status(jid, status)
        statii(jid) << status
      end

      def fake!
        @fake = true
      end

      def fake?
        @fake
      end

      def disable!
        @fake   = false
        @statii = nil
      end

      def clear!
        disable!
      end
    end
  end

  class ClientMiddleware

    def store_for_id(id, status_updates, expiration = nil, redis_pool = nil)
      if Sidekiq::Testing.fake?
        Sidekiq::Status::Testing.fake! unless Sidekiq::Status::Testing.fake?
        Sidekiq::Status::Testing.push_status id, status_updates
      else
        super
      end
    end
  end
end
