# frozen_string_literal: true

class ReportMailerPreview < ActionMailer::Preview
  def request_limits
    ReportMailer.request_limits date: Date.yesterday, reports: [
      OpenStruct.new(
        request_count: 3_401,
        request_limit: 5_000,
        active_licensed_user_count: 51,
        license_count: 3_102,
        license_limit: 50,
        product_count: 1,
        product_limit: 1,
        admin_count: 1,
        admin_limit: 1,
        account: Account.new(id: SecureRandom.uuid, name: 'Foo', slug: 'foo', plan: Plan.new(name: 'Business', price: nil), billing: Billing.new(state: 'subscribed')),
        admin: User.new(first_name: 'John', last_name: 'Doe', email: 'john@example.com')
      ),
      OpenStruct.new(
        request_count: 6_199,
        request_limit: 5_000,
        active_licensed_user_count: 430,
        license_count: 932,
        license_limit: 100_000,
        product_count: 1,
        product_limit: 5,
        admin_count: 4,
        admin_limit: 5,
        account: Account.new(id: SecureRandom.uuid, name: 'Bar', slug: 'bar', plan: Plan.new(name: 'Business', price: 29900), billing: Billing.new(state: 'trialing')),
        admin: User.new(first_name: 'Jane', last_name: 'Doe', email: 'jane@example.com')
      ),
      OpenStruct.new(
        request_count: 42,
        request_limit: 5_000,
        active_licensed_user_count: 499,
        license_count: 33_941,
        license_limit: 500,
        product_count: 1,
        product_limit: nil,
        admin_count: 99,
        admin_limit: 1,
        account: Account.new(id: SecureRandom.uuid, name: 'Bar', slug: 'bar', plan: Plan.new(name: 'Free', price: 0), billing: Billing.new(state: 'subscribed')),
        admin: User.new(first_name: 'Will', last_name: 'Doe', email: 'will@example.com')
      ),
      OpenStruct.new(
        request_count: 103,
        request_limit: 500,
        active_licensed_user_count: 33,
        license_count: 33,
        license_limit: 500,
        product_count: 1,
        product_limit: nil,
        admin_count: 9,
        admin_limit: nil,
        account: Account.new(id: SecureRandom.uuid, name: 'Bar', slug: 'bar', plan: Plan.new(name: 'Micro', price: 1900), billing: Billing.new(state: 'subscribed')),
        admin: User.new(first_name: 'Eliot', last_name: 'Doe', email: 'eliot@example.com')
      ),
      OpenStruct.new(
        request_count: 230_456,
        request_limit: 100_000,
        active_licensed_user_count: 12_000,
        license_count: 92_753,
        license_limit: 10_000,
        product_count: 23,
        product_limit: 3,
        admin_count: 9,
        admin_limit: 1,
        account: Account.new(id: SecureRandom.uuid, name: 'Bar', slug: 'bar', plan: Plan.new(name: 'Enterprise', price: 99900), billing: Billing.new(state: 'subscribed')),
        admin: User.new(first_name: 'Pete', last_name: 'Doe', email: 'pete@example.com')
      )
    ]
  end
end
