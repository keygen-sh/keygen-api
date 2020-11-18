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
        start_date: Time.at(BEGINNING_OF_PERIOD),
        end_date: Time.at(END_OF_PERIOD),
        annually_recurring_revenue: monthly_recurring_revenue * 12,
        monthly_recurring_revenue: monthly_recurring_revenue,
        average_revenue_per_user: average_revenue_per_user,
        average_subscription_length_per_user: average_subscription_length_per_user,
        average_life_time_value: average_life_time_value,
        average_time_to_convert: average_time_to_convert,
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

    attr_reader :cache

    def monthly_recurring_revenue
      revenue_per_user.sum(0.0)
    end

    def average_revenue_per_user
      revenue_per_user.sum(0.0) / revenue_per_user.size
    end

    def average_subscription_length_per_user
      subscription_lengths_in_months = paid_subscriptions
        .map { |s| ((s.ended_at.present? ? Time.at(s.ended_at) : Time.now) - Time.at(s.created)) / 1.month }

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

    def invoices_for(resource)
      cache.fetch("stripe:stats:invoices:#{resource.id}", expires_in: 1.hour) do
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
        .filter { |s| s.status == 'active' || s.status == 'past_due' || s.status == 'trialing' }
        .filter do |s|
          invoices = invoices_for(s)

          invoices.any? { |i| i.paid? && i.amount_paid > 0 } ||
            s.customer.default_source.present? ||
            s.customer.invoice_settings.default_payment_method.present?
        end
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
    s << "\e[34mReport for \e[32m#{report.start_date.strftime('%b %d')}\e[34m – \e[32m#{report.end_date.strftime('%b %d, %Y')}\e[0m\n"
    s << "\e[34m======================\e[0m\n"
    s << "\e[34mAnnually Recurring Revenue: \e[32m#{report.annually_recurring_revenue.to_s(:currency)}\e[0m\n"
    s << "\e[34mMonthly Recurring Revenue: \e[32m#{report.monthly_recurring_revenue.to_s(:currency)}\e[0m\n"
    s << "\e[34mAverage Revenue Per-User: \e[32m#{report.average_revenue_per_user.to_s(:currency)}/mo\e[0m\n"
    s << "\e[34mAverage Lifetime Value: \e[32m#{report.average_life_time_value.to_s(:currency)}\e[0m\n"
    s << "\e[34mAverage Lifetime: \e[36m#{report.average_subscription_length_per_user.to_s(:rounded, precision: 2)} mo\e[0m\n"
    s << "\e[34mAverage Time-to-Convert: \e[36m#{report.average_time_to_convert.to_s(:rounded, precision: 2)} d\e[0m\n"
    s << "\e[34mConversion Rate: \e[36m#{report.conversion_rate.to_s(:percentage, precision: 2)}\e[0m\n"
    s << "\e[34mChurn Rate: \e[31m#{report.churn_rate.to_s(:percentage, precision: 2)}\e[0m\n"
    s << "\e[34mNew Sign Ups: \e[32m#{report.new_customers.to_s(:delimited)}\e[0m\n"
    s << "\e[34mTotal Customers: \e[32m#{report.total_customers.to_s(:delimited)}\e[34m (free + paid)\e[0m\n"
    s << "\e[34mPaid: \e[32m#{report.paid_customers.to_s(:delimited)}\e[0m\n"
    s << "\e[34mTrialing: \e[1;33m#{report.trialing_customers.to_s(:delimited)}\e[0m\n"
    s << "\e[34mFree: \e[1;33m#{report.free_customers.to_s(:delimited)}\e[0m\n"
    s << "\e[34mChurned: \e[31m#{report.churned_customers.to_s(:delimited)}\e[0m\n"

    puts s
  end
end