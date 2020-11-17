require 'ostruct'
require 'stripe'

module Stripe
  class Stats
    BEGINNING_OF_PERIOD = 4.weeks.ago.beginning_of_day.to_time.to_i
    END_OF_PERIOD = Date.today.end_of_day.to_time.to_i

    attr_reader :cache

    def initialize(cache:)
      Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY')
      Stripe.api_version = '2016-07-06' # NOTE(ezekg) For `list(status: 'all')`` support

      @cache = cache
    end

    def report
      start_date_formatted = Time.at(BEGINNING_OF_PERIOD).strftime('%b %d')
      end_date_formatted = Time.at(END_OF_PERIOD).strftime('%b %d, %Y')

      OpenStruct.new(
        billing_cycle: "#{start_date_formatted} — #{end_date_formatted}",
        annually_recurring_revenue: monthly_recurring_revenue * 12,
        monthly_recurring_revenue: monthly_recurring_revenue,
        average_revenue_per_user: average_revenue_per_user,
        average_subscription_length_per_user: average_subscription_length_per_user,
        average_life_time_value: average_life_time_value,
        conversion_rate: conversion_rate,
        churn_rate: churn_rate,
        total_customers: paid_customers.size + free_customers.size,
        new_customers: new_customers.size,
        paid_customers: paid_customers.size,
        trialing_customers: trialing_customers.size,
        free_customers: free_customers.size,
        churned_customers: churned_customers.size,
      )
    end

    private

    def monthly_recurring_revenue
      revenue_per_user.sum(0.0)
    end

    def average_revenue_per_user
      revenue_per_user.sum(0.0) / revenue_per_user.size
    end

    def average_subscription_length_per_user
      converted_subsciptions = subscriptions.filter { |s| s.customer.default_source.present? || s.customer.invoice_settings.default_payment_method.present? }
      subscription_lengths_in_months = converted_subsciptions
        .map { |s| ((s.created - (s.ended_at || Time.now.to_i)).abs.to_f / 2628000) }

      subscription_lengths_in_months.sum(0.0) / converted_subsciptions.size.to_f
    end

    def average_life_time_value
      average_revenue_per_user * average_subscription_length_per_user
    end

    def conversion_rate
      converted_customers = new_customers.filter { |c| c.default_source.present? || c.invoice_settings.default_payment_method.present? }

      converted_customers.size.to_f / new_customers.size.to_f * 100
    end

    def churn_rate
      churned_customers.size.to_f / paid_customers.size.to_f * 100
    end

    def revenue_per_user
      paid_subscriptions.map do |subscription|
        plan = subscription.plan
        amount =
          if plan.interval == 'year'
            plan.amount.to_f / 12
          else
            plan.amount.to_f
          end

        amount * subscription.quantity / 100
      end
    end

    def subscriptions
      @subscriptions ||= cache.fetch('stripe:stats:subscriptions', expires_in: 1.hour) do
        Stripe::Subscription.list(status: 'all', limit: 100, expand: ['data.customer'])
          .auto_paging_each
          .to_a
          .filter { |s| !s.customer.deleted? }
          .sort_by { |s| [s.customer.id, -s.created] }
          .uniq { |s| s.customer.id }
      end
    end

    def paid_subscriptions
      @paid_subscriptions ||= subscriptions
        .filter { |s| s.status == 'active' || s.status == 'trialing' }
        .filter { |s| s.customer.default_source.present? || s.customer.invoice_settings.default_payment_method.present? }
    end

    def trialing_subscriptions
      @trailing_subscriptions ||= subscriptions.filter { |s| s.status == 'trialing' }
    end

    def free_subscriptions
      @free_subscriptions ||= subscriptions.filter { |s| s.status == 'active' && s.plan.amount == 0 }
    end

    def canceled_subscriptions
      @canceled_subscriptions ||= subscriptions.filter { |s| s.status == 'canceled' }
    end

    def customers
      @customers ||= subscriptions.map(&:customer)
    end

    def new_customers
      @new_customers ||= customers.filter { |c| c.created >= BEGINNING_OF_PERIOD }
    end

    def paid_customers
      @paid_customers ||= paid_subscriptions.map(&:customer)
    end

    def churned_customers
      @churned_customers ||= canceled_subscriptions
        .filter { |s| s.canceled_at >= BEGINNING_OF_PERIOD || s.ended_at >= BEGINNING_OF_PERIOD }
        .filter { |s| s.customer.default_source.present? || s.customer.invoice_settings.default_payment_method.present? }
        .map(&:customer)
    end

    def trialing_customers
      @trialing_customers ||= trialing_subscriptions.map(&:customer)
    end

    def free_customers
      @free_customers ||= free_subscriptions.map(&:customer)
    end
  end
end

namespace :stripe do
  desc 'calculate stripe stats'
  task stats: :environment do
    stats = Stripe::Stats.new(cache: Rails.cache)
    report = stats.report

    s = ''
    s << "\e[34mReport for #{report.billing_cycle}\e[0m\n"
    s << "\e[34m======================\e[0m\n"
    s << "\e[34mAnnually Recurring Revenue: \e[32m#{report.annually_recurring_revenue.to_s(:currency)}\e[0m\n"
    s << "\e[34mMonthly Recurring Revenue: \e[32m#{report.monthly_recurring_revenue.to_s(:currency)}\e[0m\n"
    s << "\e[34mAverage Revenue Per-User: \e[32m#{report.average_revenue_per_user.to_s(:currency)}/mo\e[0m\n"
    s << "\e[34mAverage Lifetime Value: \e[32m#{report.average_life_time_value.to_s(:currency)}\e[0m\n"
    s << "\e[34mAverage Lifetime: \e[36m#{report.average_subscription_length_per_user.to_s(:rounded, precision: 2)} mo\e[0m\n"
    s << "\e[34mConversion Rate: \e[36m#{report.conversion_rate.to_s(:percentage, precision: 2)}\e[0m\n"
    s << "\e[34mChurn Rate: \e[31m#{report.churn_rate.to_s(:percentage, precision: 2)}\e[0m\n"
    s << "\e[34mCustomers: \e[0m\n"
    s << "\e[34m  New Sign Ups: \e[32m#{report.new_customers.to_s(:delimited)}\e[0m\n"
    s << "\e[34m  Total: \e[32m#{report.total_customers.to_s(:delimited)}\e[0m\n"
    s << "\e[34m  Paid: \e[32m#{report.paid_customers.to_s(:delimited)}\e[0m\n"
    s << "\e[34m  Trialing: \e[1;33m#{report.trialing_customers.to_s(:delimited)}\e[0m\n"
    s << "\e[34m  Free: \e[1;33m#{report.free_customers.to_s(:delimited)}\e[0m\n"
    s << "\e[34m  Churned: \e[31m#{report.churned_customers.to_s(:delimited)}\e[0m\n"

    puts s
  end
end