# frozen_string_literal: true

module Billings
  class DeleteSubscriptionService < BaseService

    def initialize(subscription:, at_period_end: true)
      @subscription = subscription
      @at_period_end = at_period_end
    end

    def call
      s = Billings::Subscription.retrieve(subscription)

      # FIXME(ezekg) Release any schedules currently on the subscription,
      #              which can prevent cancelation.
      if s.respond_to?(:schedule) && s.schedule.present?
        sch = Billings::Schedule.retrieve(s.schedule)
        sch.release
      end

      s.delete(at_period_end: at_period_end)
    rescue Billings::Error => e
      error_code = e.json_body.dig(:error, :code) rescue nil

      Keygen.logger.exception(e) unless
        error_code == 'resource_missing'

      nil
    end

    private

    attr_reader :subscription, :at_period_end
  end
end
