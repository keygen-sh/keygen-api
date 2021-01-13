require 'action_view/helpers'
require 'ostruct'
require 'stripe'

include ActionView::Helpers::DateHelper

module Stripe
  class Stats
    START_DATE = ENV.fetch('START_DATE') { 4.weeks.ago.beginning_of_day.to_time }.to_i
    END_DATE = ENV.fetch('END_DATE') { Date.today.end_of_day.to_time }.to_i
    FREE_TIER_PRODUCT_ID = 'prod_DvO2JQ0AtwO7Tp'

    def initialize(cache:)
      Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY')
      Stripe.api_version = '2016-07-06' # NOTE(ezekg) For `list(status: 'all')`` support

      @cache = cache
    end

    def report
      OpenStruct.new(
        start_date: reporting_start_date,
        end_date: reporting_end_date,
        annual_run_rate: annual_run_rate,
        monthly_recurring_revenue: monthly_recurring_revenue,
        pending_revenue: pending_revenue,
        forecasted_revenue_4w: forecasted_revenue_4w,
        forecasted_revenue_3m: forecasted_revenue_3m,
        forecasted_revenue_6m: forecasted_revenue_6m,
        forecasted_revenue_1y: forecasted_revenue_1y,
        new_revenue: new_revenue,
        lost_revenue: lost_revenue,
        net_new_revenue: net_new_revenue,
        average_revenue_per_user: average_revenue_per_user,
        average_subscription_length_per_user: average_subscription_length_per_user,
        average_life_time_value: average_life_time_value,
        latest_time_to_convert: latest_time_to_convert,
        average_time_to_convert: average_time_to_convert,
        median_time_to_convert: median_time_to_convert,
        p90_time_to_convert: p90_time_to_convert,
        p95_time_to_convert: p95_time_to_convert,
        p99_time_to_convert: p99_time_to_convert,
        latest_converted_user: latest_converted_user,
        latest_time_on_free: latest_time_on_free,
        average_time_on_free: average_time_on_free,
        median_time_on_free: median_time_on_free,
        p90_time_on_free: p90_time_on_free,
        p95_time_on_free: p95_time_on_free,
        p99_time_on_free: p99_time_on_free,
        conversion_rate_90d: conversion_rate_90d,
        conversion_rate_1y: conversion_rate_1y,
        conversion_rate_ytd: conversion_rate_ytd,
        revenue_growth_rate: revenue_growth_rate,
        paid_user_growth_rate: paid_user_growth_rate,
        user_growth_rate: user_growth_rate,
        churn_rate: churn_rate,
        total_users: total_users_count,
        paid_users_percentage: paid_users_percentage,
        free_users_percentage: free_users_percentage,
        new_sign_ups: new_sign_ups_count,
        paid_users: paid_users_count,
        new_paid_users: new_paid_users_count,
        trialing_users: trialing_users_count,
        trialing_users_with_payment_method: trialing_users_with_payment_method_count,
        free_users: free_users_count,
        at_risk_users: at_risk_users_count,
        churned_users: churned_users_count,
      )
    end

    def reporting_start_date
      Time.at(START_DATE)
    end

    def reporting_end_date
      Time.at(END_DATE)
    end

    def new_sign_ups_count
      new_sign_ups.size
    end

    def paid_users_count
      paid_users.size
    end

    def new_paid_users_count
      new_paid_users.size
    end

    def trialing_users_count
      trialing_users.size
    end

    def trialing_users_with_payment_method_count
      trialing_users_with_payment_method.size
    end

    def free_users_count
      free_users.size
    end

    def at_risk_users_count
      at_risk_users.size
    end

    def churned_users_count
      churned_users.size
    end

    def total_users_count
      paid_users.size + trialing_users.size + free_users.size
    end

    def paid_users_percentage
      paid_users_count.to_f / total_users_count.to_f * 100
    end

    def free_users_percentage
      free_users_count.to_f / total_users_count.to_f * 100
    end

    def monthly_recurring_revenue
      revenue_per_user.sum(0.0)
    end

    def annual_run_rate
      monthly_recurring_revenue * 12
    end

    def pending_revenue
      pending_revenue_per_user.sum(0.0)
    end

    def new_revenue
      revenue_per_new_user.sum(0.0)
    end

    def lost_revenue
      revenue_per_churned_user.sum(0.0)
    end

    def net_new_revenue
      new_revenue - lost_revenue
    end

    def forecasted_revenue_4w
      current_revenue = monthly_recurring_revenue

      current_revenue + current_revenue * (revenue_growth_rate / 100)
    end

    def forecasted_revenue_3m
      current_revenue = monthly_recurring_revenue

      current_revenue + current_revenue * (revenue_growth_rate * 3 / 100)
    end

    def forecasted_revenue_6m
      current_revenue = monthly_recurring_revenue

      current_revenue + current_revenue * (revenue_growth_rate * 6 / 100)
    end

    def forecasted_revenue_1y
      current_revenue = monthly_recurring_revenue

      current_revenue + current_revenue * (revenue_growth_rate * 12 / 100)
    end

    def average_revenue_per_user
      revenue_per_user.sum(0.0) / revenue_per_user.size
    end

    def average_subscription_length_per_user
      subscription_lengths_in_months = converted_subscriptions
        .map { |s| subscription_length_for(s) }

      subscription_lengths_in_months.sum(0.0) / subscription_lengths_in_months.size.to_f
    end

    def average_life_time_value
      average_revenue_per_user * average_subscription_length_per_user
    end

    def latest_time_to_convert
      days_to_convert.last
    end

    def average_time_to_convert
      days_to_convert.sum(0.0) / days_to_convert.size.to_f
    end

    def median_time_to_convert
      sorted_times = days_to_convert.sort
      mid_idx = days_to_convert.size / 2

      if days_to_convert.size.even?
        (sorted_times[mid_idx] + sorted_times[mid_idx - 1]) / 2
      else
        sorted_times[mid_idx]
      end
    end

    def p90_time_to_convert
      quantile(days_to_convert, 0.90)
    end

    def p95_time_to_convert
      quantile(days_to_convert, 0.95)
    end

    def p99_time_to_convert
      quantile(days_to_convert, 0.99)
    end

    def latest_time_on_free
      days_on_free.last
    end

    def average_time_on_free
      days_on_free.sum(0.0) / days_on_free.size.to_f
    end

    def median_time_on_free
      sorted_times = days_on_free.sort
      mid_idx = days_on_free.size / 2

      if days_on_free.size.even?
        (sorted_times[mid_idx] + sorted_times[mid_idx - 1]) / 2
      else
        sorted_times[mid_idx]
      end
    end

    def p90_time_on_free
      quantile(days_on_free, 0.90)
    end

    def p95_time_on_free
      quantile(days_on_free, 0.95)
    end

    def p99_time_on_free
      quantile(days_on_free, 0.99)
    end

    def conversion_rate_90d
      conversion_rate_for(90.days.ago)
    end

    def conversion_rate_1y
      conversion_rate_for(1.year.ago)
    end

    def conversion_rate_ytd
      conversion_rate_for(Time.now.beginning_of_year)
    end

    def conversion_rate_for(period)
      recent_conversions = paid_users.filter { |c| Time.at(c.created) >= period }
      recent_sign_ups = customers.filter { |c| Time.at(c.created) >= period }

      recent_conversions.size.to_f / recent_sign_ups.size.to_f * 100
    end

    def revenue_growth_rate
      next_mrr = monthly_recurring_revenue
      prev_mrr = (next_mrr - new_revenue) + lost_revenue

      (next_mrr - prev_mrr) / prev_mrr * 100
    end

    def paid_user_growth_rate
      next_paid_user_count = paid_users.size.to_f
      prev_paid_user_count = (next_paid_user_count - new_paid_users.size.to_f) + churned_users.size.to_f

      (next_paid_user_count - prev_paid_user_count) / prev_paid_user_count * 100
    end

    def user_growth_rate
      next_user_count = paid_users.size.to_f + trialing_users.size.to_f + free_users.size.to_f
      prev_user_count = next_user_count - new_sign_ups.size.to_f

      (next_user_count - prev_user_count) / prev_user_count * 100
    end

    def churn_rate
      paid_users_at_period_start = (paid_users.size - new_paid_users.size) + churned_users.size

      churned_users.size.to_f / paid_users_at_period_start.to_f * 100
    end

    def days_to_convert
      @days_to_convert ||= paid_subscriptions
        .map do |s|
          invoices = invoices_for(s.customer)
          first_paid_invoice = invoices.find { |i| i.amount_paid > 0 }
          next if first_paid_invoice.nil?

          (Time.at(first_paid_invoice.status_transitions.paid_at) - Time.at(s.customer.created)) / 1.day
        end.compact
    end

    def days_on_free
      @days_on_free ||= paid_subscriptions
        .map do |s|
          invoices = invoices_for(s.customer)
          next unless invoices.any? { |i|
            i.lines.data.any? { |l| l.price&.product == FREE_TIER_PRODUCT_ID }
          }

          first_paid_invoice = invoices.find { |i| i.amount_paid > 0 }
          next if first_paid_invoice.nil?

          (Time.at(first_paid_invoice.status_transitions.paid_at) - Time.at(s.customer.created)) / 1.day
        end.compact
    end

    def latest_converted_user
      @latest_converted_user ||= paid_subscriptions
        .map do |s|
          invoices = invoices_for(s.customer)
          next unless invoices.any? { |i|
            i.lines.data.any? { |l| l.price&.product == FREE_TIER_PRODUCT_ID }
          }

          first_paid_invoice = invoices.find { |i| i.amount_paid > 0 }
          next if first_paid_invoice.nil?

          s.customer
        end.compact.last
    end

    def revenue_per_user
      revenues_for(paid_subscriptions)
    end

    def pending_revenue_per_user
      revenues_for(paid_subscriptions.filter { |s| s.status == 'trialing' })
    end

    def revenue_per_new_user
      revenues_for(new_paid_subscriptions)
    end

    def revenue_per_churned_user
      revenues_for(churned_subscriptions)
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
      @invoices_for ||= {}

      @invoices_for[resource.id] ||= to_struct(
        JSON.parse(
          cache.fetch("stripe:stats:invoices:#{resource.id}", raw: true, expires_in: 2.days) do
            invoices =
              case resource.object
              when 'subscription'
                Stripe::Invoice.list(subscription: resource.id, expand: ['data.subscription'], limit: 100).auto_paging_each.to_a
              when 'customer'
                Stripe::Invoice.list(customer: resource.id, expand: ['data.subscription'], limit: 100).auto_paging_each.to_a
              else
                []
              end

            invoices
              &.sort_by { |i| i.created }
              .to_json
          end
        )
      )
    end

    def subscriptions
      @subscriptions ||= to_struct(
        JSON.parse(
          cache.fetch('stripe:stats:subscriptions', raw: true, expires_in: 2.days) do
            Stripe::Subscription.list(status: 'all', limit: 100, expand: ['data.customer'])
              .auto_paging_each
              .to_a
              .filter { |s| !s.customer.deleted? }
              .sort_by { |s| [s.customer.id, -s.created] }
              .uniq { |s| s.customer.id }
              .to_json
          end
        )
      )
    end

    def paid_subscriptions
      @paid_subscriptions ||= subscriptions
        .filter { |s| s.status == 'active' || s.status == 'past_due' || s.status == 'trialing' }
        .filter do |s|
          next if s.plan.product == FREE_TIER_PRODUCT_ID

          invoices = invoices_for(s)

          invoices.any? { |i| i.amount_paid > 0 } ||
            s.customer.default_source.present? ||
            s.customer.invoice_settings.default_payment_method.present?
        end
    end

    def new_paid_subscriptions
      @new_paid_subscriptions ||= paid_subscriptions.filter do |s|
        next if s.plan.product == FREE_TIER_PRODUCT_ID

        invoices = invoices_for(s)
        first_paid_invoice = invoices.find { |i| i.amount_paid > 0 }
        next if first_paid_invoice.nil?

        first_paid_invoice.status_transitions.paid_at >= START_DATE
      end
    end

    def trialing_subscriptions
      @trialing_subscriptions ||= subscriptions.filter { |s| s.status == 'trialing' }
    end

    def free_subscriptions
      @free_subscriptions ||= subscriptions.filter { |s| s.status == 'active' && s.plan.product == FREE_TIER_PRODUCT_ID }
    end

    def canceled_subscriptions
      @canceled_subscriptions ||= subscriptions.filter { |s| s.status == 'canceled' }
    end

    def churned_subscriptions
      @churned_subscriptions ||= canceled_subscriptions
        .filter { |s| s.canceled_at >= START_DATE || s.ended_at >= START_DATE }
        .filter { |s| s.customer.default_source.present? || s.customer.invoice_settings.default_payment_method.present? }
    end

    def at_risk_subscriptions
      @at_risk_subscriptions ||= subscriptions
        .filter { |s| s.status == 'past_due' }
        .filter { |s| !s.customer.default_source.present? && !s.customer.invoice_settings.default_payment_method.present? }
    end

    def converted_subscriptions
      @converted_subscriptions ||= subscriptions
        .filter { |s| s.status == 'active' || s.status == 'canceled' }
        .filter { |s| s.customer.default_source.present? || s.customer.invoice_settings.default_payment_method.present? }
        .filter do |s|
          next if s.plan.product == FREE_TIER_PRODUCT_ID

          invoices = invoices_for(s)

          invoices.any? { |i| i.amount_paid > 0 }
        end
    end

    def customers
      @customers ||= subscriptions.map(&:customer)
    end

    def new_sign_ups
      @new_sign_ups ||= customers.filter { |c| c.created >= START_DATE }
    end

    def paid_users
      @paid_users ||= paid_subscriptions.map(&:customer)
    end

    def new_paid_users
      @new_paid_users ||= new_paid_subscriptions.map(&:customer)
    end

    def churned_users
      @churned_users ||= churned_subscriptions.map(&:customer)
    end

    def trialing_users
      @trialing_users ||= trialing_subscriptions.map(&:customer)
    end

    def trialing_users_with_payment_method
      @trialing_users_with_payment_method ||= trialing_users
        .filter { |c| c.default_source.present? || c.invoice_settings.default_payment_method.present? }
    end

    def free_users
      @free_users ||= free_subscriptions.map(&:customer)
    end

    def at_risk_users
      @at_risk_users ||= at_risk_subscriptions.map(&:customer)
    end

    def converted_users
      @converted_users ||= converted_subscriptions.map(&:customer)
    end

    private

    attr_reader :cache

    def to_struct(object)
      case object
      when Hash
        OpenStruct.new(object.each_with_object({}) { |(k, v), h| h[k] = to_struct(v) })
      when Array
        object.map { |v| to_struct(v) }
      else
        object
      end
    end

    def quantile(values, percentile)
      return values.first if values.size == 1

      sorted = values.sort
      k = (percentile * (sorted.size - 1) + 1).floor - 1
      f = (percentile * (sorted.size - 1) + 1).modulo(1)

      return sorted[k] + (f * (sorted[k + 1] - sorted[k]))
    end

    class Spinner
      @@thread = nil

      def self.start(&block)
        print "\u001B[?25l"

        @@thread = Thread.new do
          frames = %w[⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏]
          frames.cycle do |frame, i|
            clear!

            print "\e[36m#{frame}\e[34m generating report…\e[0m"

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

        clear!

        @@thread.kill
      end

      private

      def self.clear!
        print "\b" * 80
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
      t1 = Time.now
      t2 = nil

      Stripe::Stats::Spinner.start do
        report = stats.report
        t2 = Time.now
      end

      s = ''
      s << "\e[34m======================\e[0m\n"
      s << "\e[34mReport for \e[32m#{report.start_date.strftime('%b %d')}\e[34m – \e[32m#{report.end_date.strftime('%b %d, %Y')}\e[34m (last 4 weeks)\e[0m\n"
      s << "\e[34m======================\e[0m\n"
      s << "\e[34mMonthly Recurring Revenue: \e[32m#{report.monthly_recurring_revenue.to_s(:currency)}\e[34m (#{report.pending_revenue.to_s(:currency)} pending conversion)\e[0m\n"
      s << "\e[34mAnnual Run Rate: \e[32m#{report.annual_run_rate.to_s(:currency)}\e[0m\n"
      s << "\e[34mNew Revenue: \e[32m#{report.new_revenue.to_s(:currency)}/mo\e[34m (#{report.net_new_revenue.to_s(:currency)} net)\e[0m\n"
      s << "\e[34mLost Revenue: \e[31m#{report.lost_revenue.to_s(:currency)}/mo\e[0m\n"
      s << "\e[34mRevenue Growth Rate: \e[32m#{report.revenue_growth_rate.to_s(:percentage, precision: 2)}\e[0m\n"
      s << "\e[34mConversion Rate:\e[0m\n"
      s << "\e[34m  - Past 90 Days: \e[36m#{report.conversion_rate_90d.to_s(:percentage, precision: 2)}\e[0m\n"
      s << "\e[34m  - 1 Year: \e[36m#{report.conversion_rate_1y.to_s(:percentage, precision: 2)}\e[0m\n"
      s << "\e[34m  - YTD: \e[36m#{report.conversion_rate_ytd.to_s(:percentage, precision: 2)}\e[0m\n"
      s << "\e[34mChurn Rate: \e[31m#{report.churn_rate.to_s(:percentage, precision: 2)}\e[0m\n"
      s << "\e[34mUser Growth Rate:\e[0m\n"
      s << "\e[34m  - Overall: \e[32m#{report.user_growth_rate.to_s(:percentage, precision: 2)}\e[0m\n"
      s << "\e[34m  - Paid: \e[32m#{report.paid_user_growth_rate.to_s(:percentage, precision: 2)}\e[0m\n"
      s << "\e[34mForecasted Revenue:\e[0m\n"
      s << "\e[34m  - Next 4 Weeks: \e[32m#{report.forecasted_revenue_4w.to_s(:currency)}/mo\e[34m (with #{report.revenue_growth_rate.to_s(:percentage, precision: 2)} growth rate)\e[0m\n"
      s << "\e[34m  - 3 Months: \e[32m#{report.forecasted_revenue_3m.to_s(:currency)}/mo\e[0m\n"
      s << "\e[34m  - 6 Months: \e[32m#{report.forecasted_revenue_6m.to_s(:currency)}/mo\e[0m\n"
      s << "\e[34m  - 1 Year: \e[32m#{report.forecasted_revenue_1y.to_s(:currency)}/mo\e[0m\n"
      s << "\e[34mAverage Revenue Per-User: \e[32m#{report.average_revenue_per_user.to_s(:currency)}/mo\e[0m\n"
      s << "\e[34mAverage Lifetime Value: \e[32m#{report.average_life_time_value.to_s(:currency)}\e[0m\n"
      s << "\e[34mAverage Lifetime: \e[36m#{report.average_subscription_length_per_user.to_s(:rounded, precision: 2)} months\e[0m\n"
      s << "\e[34mTime-to-Convert:\e[0m\n"
      s << "\e[34m  - Latest: \e[36m#{report.latest_time_to_convert.to_s(:rounded, precision: 2)} days\e[34m (#{report.latest_converted_user.email} signed up #{time_ago_in_words(report.latest_converted_user.created)} ago)\e[0m\n"
      s << "\e[34m  - Average: \e[36m#{report.average_time_to_convert.to_s(:rounded, precision: 2)} days\e[0m\n"
      s << "\e[34m  - Median: \e[36m#{report.median_time_to_convert.to_s(:rounded, precision: 2)} days\e[0m\n"
      s << "\e[34m  - P90: \e[36m#{report.p90_time_to_convert.to_s(:rounded, precision: 2)} days\e[0m\n"
      s << "\e[34m  - P95: \e[36m#{report.p95_time_to_convert.to_s(:rounded, precision: 2)} days\e[0m\n"
      s << "\e[34m  - P99: \e[36m#{report.p99_time_to_convert.to_s(:rounded, precision: 2)} days\e[0m\n"
      s << "\e[34mTime-on-Free:\e[34m (of those which convert)\e[0m\n"
      s << "\e[34m  - Latest: \e[36m#{report.latest_time_on_free.to_s(:rounded, precision: 2)} days\e[0m\n"
      s << "\e[34m  - Average: \e[36m#{report.average_time_on_free.to_s(:rounded, precision: 2)} days\e[0m\n"
      s << "\e[34m  - Median: \e[36m#{report.median_time_on_free.to_s(:rounded, precision: 2)} days\e[0m\n"
      s << "\e[34m  - P90: \e[36m#{report.p90_time_on_free.to_s(:rounded, precision: 2)} days\e[0m\n"
      s << "\e[34m  - P95: \e[36m#{report.p95_time_on_free.to_s(:rounded, precision: 2)} days\e[0m\n"
      s << "\e[34m  - P99: \e[36m#{report.p99_time_on_free.to_s(:rounded, precision: 2)} days\e[0m\n"
      s << "\e[34mUsers:\e[0m\n"
      s << "\e[34m  - Total: \e[32m#{report.total_users.to_s(:delimited)}\e[34m (free + paid)\e[0m\n"
      s << "\e[34m  - New: \e[32m#{report.new_sign_ups.to_s(:delimited)}\e[34m (new sign ups)\e[0m\n"
      s << "\e[34m  - At-Risk: \e[33m#{report.at_risk_users.to_s(:delimited)}\e[34m (overdue, no payment method, etc.)\e[0m\n"
      s << "\e[34m  - Trialing: \e[33m#{report.trialing_users.to_s(:delimited)}\e[34m (#{report.trialing_users_with_payment_method.to_s(:delimited)} w/ payment method)\e[0m\n"
      s << "\e[34m  - Free: \e[36m#{report.free_users.to_s(:delimited)}\e[34m (#{report.free_users_percentage.to_s(:percentage, precision: 2)} of users)\e[0m\n"
      s << "\e[34m  - Paid: \e[32m#{report.paid_users.to_s(:delimited)}\e[34m (#{report.new_paid_users.to_s(:delimited)} new)\e[0m\n"
      s << "\e[34m  - Churned: \e[31m#{report.churned_users.to_s(:delimited)}\e[0m\n"
      s << "\e[34m======================\e[0m\n"
      s << "\e[34mTime elapsed: #{distance_of_time_in_words(t1, t2, include_seconds: true)}\e[0m\n"
      s << "\e[34m======================\e[0m\n"

      puts s
    end
  end

  desc 'retrieve churned customers'
  task churn: :environment do
    Rails.logger.silence do
      stats = Stripe::Stats.new(cache: Rails.cache)
      churned_subscriptions = nil
      at_risk_subscriptions = nil
      lost_revenue = nil
      churn_rate = nil
      t1 = Time.now
      t2 = nil

      Stripe::Stats::Spinner.start do
        churned_subscriptions = stats.churned_subscriptions
        at_risk_subscriptions = stats.at_risk_subscriptions
        lost_revenue = stats.lost_revenue
        churn_rate = stats.churn_rate
        t2 = Time.now
      end

      s = ''
      s << "\e[34m======================\e[0m\n"
      s << "\e[34mChurn for \e[33m#{stats.reporting_start_date.strftime('%b %d')}\e[34m – \e[33m#{stats.reporting_end_date.strftime('%b %d, %Y')}\e[34m (last 4 weeks)\e[0m\n"
      s << "\e[34m======================\e[0m\n"
      s << "\e[34mLost Revenue: \e[31m#{lost_revenue.to_s(:currency)}/mo\e[0m\n"
      s << "\e[34mChurn Rate: \e[31m#{churn_rate.to_s(:percentage, precision: 2)}\e[0m\n"
      s << "\e[34mChurned:\e[34m (\e[31m#{churned_subscriptions.size.to_s(:delimited)}\e[34m total)\e[0m\n"

      churned_subscriptions.each do |subscription|
        life_time = stats.subscription_length_for(subscription)
        life_time_value = stats.revenue_for(subscription) * life_time
        customer = subscription.customer

        s << "\e[34m  - \e[31m#{customer.email}\e[34m canceled #{time_ago_in_words(subscription.canceled_at || subscription.ended_at)} ago (LT=#{life_time.to_s(:rounded, precision: 2)}mo LTV=#{life_time_value.to_s(:currency)})\e[0m\n"
      end

      s << "\e[34mAt-Risk:\e[34m (\e[33m#{at_risk_subscriptions.size.to_s(:delimited)}\e[34m total)\e[0m\n"

      at_risk_subscriptions.each do |subscription|
        life_time = stats.subscription_length_for(subscription)
        life_time_value = stats.revenue_for(subscription) * life_time
        customer = subscription.customer

        s << "\e[34m  - \e[33m#{customer.email}\e[34m (LT=#{life_time.to_s(:rounded, precision: 2)}mo LTV=#{life_time_value.to_s(:currency)})\e[0m\n"
      end

      s << "\e[34m======================\e[0m\n"
      s << "\e[34mTime elapsed: #{distance_of_time_in_words(t1, t2, include_seconds: true)}\e[0m\n"
      s << "\e[34m======================\e[0m\n"

      puts s
    end
  end
end