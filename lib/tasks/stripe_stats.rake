require 'ostruct'
require 'stripe'

module Stripe
  class Stats
    BEGINNING_OF_PERIOD = 4.weeks.ago.beginning_of_day.to_time.to_i
    END_OF_PERIOD = Date.today.end_of_day.to_time.to_i

    def initialize(cache:)
      Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY')
      Stripe.api_version = '2016-07-06' # NOTE(ezekg) For `list(status: 'all')`` support

      @cache = cache
    end

    def report
      OpenStruct.new(
        start_date: reporting_start_date,
        end_date: reporting_end_date,
        monthly_recurring_revenue: monthly_recurring_revenue,
        annual_run_rate: monthly_recurring_revenue * 12,
        new_revenue: new_revenue,
        average_revenue_per_user: average_revenue_per_user,
        average_subscription_length_per_user: average_subscription_length_per_user,
        average_life_time_value: average_life_time_value,
        average_time_to_convert: average_time_to_convert,
        conversion_rate: conversion_rate,
        revenue_growth_rate: revenue_growth_rate,
        user_growth_rate: user_growth_rate,
        churn_rate: churn_rate,
        total_customers: paid_customers.size + trialing_customers.size + free_customers.size,
        new_sign_ups: new_sign_ups.size,
        paid_customers: paid_customers.size,
        new_paid_customers: new_paid_customers.size,
        trialing_customers: trialing_customers.size,
        trialing_customers_with_payment_method: trialing_customers_with_payment_method.size,
        free_customers: free_customers.size,
        churned_customers: churned_customers.size,
      )
    end

    def reporting_start_date
      Time.at(BEGINNING_OF_PERIOD)
    end

    def reporting_end_date
      Time.at(END_OF_PERIOD)
    end

    def monthly_recurring_revenue
      revenue_per_user.sum(0.0)
    end

    def new_revenue
      revenue_per_new_user.sum(0.0)
    end

    def average_revenue_per_user
      revenue_per_user.sum(0.0) / revenue_per_user.size
    end

    def average_subscription_length_per_user
      subscription_lengths_in_months = paid_subscriptions
        .map { |s| subscription_length_for(s) }

      subscription_lengths_in_months.sum(0.0) / subscription_lengths_in_months.size.to_f
    end

    def average_life_time_value
      average_revenue_per_user * average_subscription_length_per_user
    end

    def average_time_to_convert
      days_to_convert = paid_subscriptions.map do |s|
        invoices = invoices_for(s.customer)
        first_paid_invoice = invoices.find { |i| i.paid? && i.amount_paid > 0 }
        next if first_paid_invoice.nil?

        (Time.at(first_paid_invoice.status_transitions.paid_at) - Time.at(s.customer.created)) / 1.day
      end.compact

      days_to_convert.sum(0.0) / days_to_convert.size.to_f
    end

    def conversion_rate
      recent_conversions = paid_customers.filter { |c| Time.at(c.created) >= 90.days.ago }
      recent_sign_ups = customers.filter { |c| Time.at(c.created) >= 90.days.ago }

      recent_conversions.size.to_f / recent_sign_ups.size.to_f * 100
    end

    def revenue_growth_rate
      next_mrr = monthly_recurring_revenue
      prev_mrr = next_mrr - new_revenue

      (next_mrr - prev_mrr) / prev_mrr * 100
    end

    def user_growth_rate
      next_user_count = paid_customers.size.to_f + trialing_customers.size.to_f + free_customers.size.to_f
      prev_user_count = next_user_count - new_sign_ups.size.to_f

      (next_user_count - prev_user_count) / prev_user_count * 100
    end

    def churn_rate
      churned_customers.size.to_f / paid_customers.size.to_f * 100
    end

    def revenue_per_user
      revenues_for(paid_subscriptions)
    end

    def revenue_per_new_user
      revenues_for(new_paid_subscriptions)
    end

    def revenue_for(subscription)
      coupon = subscription.discount&.coupon
      plan = subscription.plan
      amount =
        if plan.interval == 'year'
          plan.amount.to_f / 12
        else
          plan.amount.to_f
        end
      discount =
        if coupon.present? && coupon.duration == 'forever'
          amount * (coupon.percent_off.to_f / 100)
        else
          0.0
        end

      (amount - discount) * subscription.quantity / 100
    end

    def revenues_for(subscriptions)
      subscriptions.map { |s| revenue_for(s) }
    end

    def subscription_length_for(subscription)
      end_date = subscription.ended_at.present? ? Time.at(subscription.ended_at) : Time.now
      start_date = Time.at(subscription.created)

      (end_date - start_date) / 1.month
    end

    def invoices_for(resource)
      cache.fetch("stripe:stats:invoices:#{resource.id}", expires_in: 2.days) do
        invoices =
          case resource
          when Stripe::Subscription
            Stripe::Invoice.list(subscription: resource.id, limit: 100).auto_paging_each.to_a
          when Stripe::Customer
            Stripe::Invoice.list(customer: resource.id, limit: 100).auto_paging_each.to_a
          end

        invoices&.sort_by { |i| i.created }
      end
    end

    def subscriptions
      @subscriptions ||= cache.fetch('stripe:stats:subscriptions', expires_in: 2.days) do
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
        .filter { |s| s.status == 'active' || s.status == 'past_due' || s.status == 'trialing' }
        .filter do |s|
          invoices = invoices_for(s)

          invoices.any? { |i| i.paid? && i.amount_paid > 0 } ||
            s.customer.default_source.present? ||
            s.customer.invoice_settings.default_payment_method.present?
        end
    end

    def new_paid_subscriptions
      @new_paid_subscriptions ||= paid_subscriptions.filter do |s|
        invoices = invoices_for(s)
        first_paid_invoice = invoices.find { |i| i.paid? && i.amount_paid > 0 }
        next if first_paid_invoice.nil?

        first_paid_invoice.status_transitions.paid_at >= BEGINNING_OF_PERIOD
      end.compact
    end

    def trialing_subscriptions
      @trialing_subscriptions ||= subscriptions.filter { |s| s.status == 'trialing' }
    end

    def free_subscriptions
      @free_subscriptions ||= subscriptions.filter { |s| s.status == 'active' && s.plan.amount == 0 }
    end

    def canceled_subscriptions
      @canceled_subscriptions ||= subscriptions.filter { |s| s.status == 'canceled' }
    end

    def churned_subscriptions
      @churned_subscriptions ||= canceled_subscriptions
        .filter { |s| s.canceled_at >= BEGINNING_OF_PERIOD || s.ended_at >= BEGINNING_OF_PERIOD }
        .filter { |s| s.customer.default_source.present? || s.customer.invoice_settings.default_payment_method.present? }
    end

    def customers
      @customers ||= subscriptions.map(&:customer)
    end

    def new_sign_ups
      @new_sign_ups ||= customers.filter { |c| c.created >= BEGINNING_OF_PERIOD }
    end

    def paid_customers
      @paid_customers ||= paid_subscriptions.map(&:customer)
    end

    def new_paid_customers
      @new_paid_customers ||= new_paid_subscriptions.map(&:customer)
    end

    def churned_customers
      @churned_customers ||= churned_subscriptions.map(&:customer)
    end

    def trialing_customers
      @trialing_customers ||= trialing_subscriptions.map(&:customer)
    end

    def trialing_customers_with_payment_method
      @trialing_customers_with_payment_method ||= trialing_customers
        .filter { |c| c.default_source.present? || c.invoice_settings.default_payment_method.present? }
    end

    def free_customers
      @free_customers ||= free_subscriptions.map(&:customer)
    end

    private

    attr_reader :cache

    class Spinner
      @@thread = nil

      def self.start(&block)
        print "\u001B[?25l"

        @@thread = Thread.new do
          frames = %w[⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏]
          frames.cycle do |frame|
            print "\e[H\e[2J\e[36m#{frame}\e[34m generating report…\e[0m\n"
            sleep 0.1
          end
        end

        if block_given?
          block.call
          stop
        end
      end

      def self.stop
        print "\u001B[?25h"
        print "\e[H\e[2J"

        @@thread.kill
      end
    end
  end
end

namespace :stripe do
  desc 'calculate stripe stats'
  task stats: :environment do
    Rails.logger.silence do
      stats = Stripe::Stats.new(cache: Rails.cache)
      report = nil

      Stripe::Stats::Spinner.start do
        report = stats.report
      end

      s = ''
      s << "\e[34m======================\e[0m\n"
      s << "\e[34mReport for \e[32m#{report.start_date.strftime('%b %d')}\e[34m – \e[32m#{report.end_date.strftime('%b %d, %Y')}\e[34m (last 4 weeks)\e[0m\n"
      s << "\e[34m======================\e[0m\n"
      s << "\e[34mMonthly Recurring Revenue: \e[32m#{report.monthly_recurring_revenue.to_s(:currency)}\e[0m\n"
      s << "\e[34mAnnual Run Rate: \e[32m#{report.annual_run_rate.to_s(:currency)}\e[0m\n"
      s << "\e[34mNew Revenue: \e[32m#{report.new_revenue.to_s(:currency)}/mo\e[0m\n"
      s << "\e[34mAverage Revenue Per-User: \e[32m#{report.average_revenue_per_user.to_s(:currency)}/mo\e[0m\n"
      s << "\e[34mAverage Lifetime Value: \e[32m#{report.average_life_time_value.to_s(:currency)}\e[0m\n"
      s << "\e[34mAverage Lifetime: \e[36m#{report.average_subscription_length_per_user.to_s(:rounded, precision: 2)} months\e[0m\n"
      s << "\e[34mAverage Time-to-Convert: \e[36m#{report.average_time_to_convert.to_s(:rounded, precision: 2)} days\e[0m\n"
      s << "\e[34mRevenue Growth Rate: \e[32m#{report.revenue_growth_rate.to_s(:percentage, precision: 2)}\e[0m\n"
      s << "\e[34mUser Growth Rate: \e[32m#{report.user_growth_rate.to_s(:percentage, precision: 2)}\e[0m\n"
      s << "\e[34mConversion Rate: \e[36m#{report.conversion_rate.to_s(:percentage, precision: 2)}\e[34m (rolling 90 days)\e[0m\n"
      s << "\e[34mChurn Rate: \e[31m#{report.churn_rate.to_s(:percentage, precision: 2)}\e[0m\n"
      s << "\e[34mNew Sign Ups: \e[32m#{report.new_sign_ups.to_s(:delimited)}\e[0m\n"
      s << "\e[34mNew Paid Customers: \e[32m#{report.new_paid_customers.to_s(:delimited)}\e[0m\n"
      s << "\e[34mTotal Customers: \e[32m#{report.total_customers.to_s(:delimited)}\e[34m (free + paid)\e[0m\n"
      s << "\e[34mPaid: \e[32m#{report.paid_customers.to_s(:delimited)}\e[0m\n"
      s << "\e[34mTrialing: \e[1;33m#{report.trialing_customers.to_s(:delimited)}\e[34m (#{report.trialing_customers_with_payment_method.to_s(:delimited)} w/ payment method)\e[0m\n"
      s << "\e[34mFree: \e[1;33m#{report.free_customers.to_s(:delimited)}\e[0m\n"
      s << "\e[34mChurned: \e[31m#{report.churned_customers.to_s(:delimited)}\e[0m\n"
      s << "\e[34m======================\e[0m\n"

      puts s
    end
  end

  desc 'retrieve churned customers'
  task churn: :environment do
    Rails.logger.silence do
      stats = Stripe::Stats.new(cache: Rails.cache)
      churned_subscriptions = nil
      churn_rate = nil

      Stripe::Stats::Spinner.start do
        churned_subscriptions = stats.churned_subscriptions
        churn_rate = stats.churn_rate
      end

      s = ''
      s << "\e[34m======================\e[0m\n"
      s << "\e[34mChurn for \e[33m#{stats.reporting_start_date.strftime('%b %d')}\e[34m – \e[33m#{stats.reporting_end_date.strftime('%b %d, %Y')}\e[34m (last 4 weeks)\e[0m\n"
      s << "\e[34m======================\e[0m\n"
      s << "\e[34mChurn Rate: \e[31m#{churn_rate.to_s(:percentage, precision: 2)}\e[0m\n"
      s << "\e[34mChurned:\e[34m (\e[31m#{churned_subscriptions.size.to_s(:delimited)}\e[34m total)\e[0m\n"

      churned_subscriptions.each do |subscription|
        life_time = stats.subscription_length_for(subscription)
        life_time_value = stats.revenue_for(subscription) * life_time
        customer = subscription.customer

        s << "\e[34m  - \e[31m#{customer.email}\e[34m (LT=#{life_time.to_s(:rounded, precision: 2)}mo LTV=#{life_time_value.to_s(:currency)})\e[0m\n"
      end

      s << "\e[34m======================\e[0m\n"

      puts s
    end
  end
end