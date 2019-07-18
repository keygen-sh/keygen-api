# frozen_string_literal: true

class ReportMailerPreview < ActionMailer::Preview
  def request_limits
    ReportMailer.request_limits date: Date.yesterday, reports: [
      OpenStruct.new(
        request_count: 3_401,
        request_limit: 5_000,
        account: Account.new(id: SecureRandom.uuid, name: 'Foo', slug: 'foo', plan: Plan.new(name: 'Business'), billing: Billing.new(state: 'subscribed')),
        admin: User.new(first_name: 'John', last_name: 'Doe', email: 'john@example.com')
      ),
      OpenStruct.new(
        request_count: 6_199,
        request_limit: 5_000,
        account: Account.new(id: SecureRandom.uuid, name: 'Bar', slug: 'bar', plan: Plan.new(name: 'Business'), billing: Billing.new(state: 'trialing')),
        admin: User.new(first_name: 'Jane', last_name: 'Doe', email: 'jane@example.com')
      ),
      OpenStruct.new(
        request_count: 42,
        request_limit: 5_000,
        account: Account.new(id: SecureRandom.uuid, name: 'Bar', slug: 'bar', plan: Plan.new(name: 'Business'), billing: Billing.new(state: 'trialing')),
        admin: User.new(first_name: 'Will', last_name: 'Doe', email: 'will@example.com')
      ),
      OpenStruct.new(
        request_count: 103,
        request_limit: 500,
        account: Account.new(id: SecureRandom.uuid, name: 'Bar', slug: 'bar', plan: Plan.new(name: 'Micro'), billing: Billing.new(state: 'subscribed')),
        admin: User.new(first_name: 'Eliot', last_name: 'Doe', email: 'eliot@example.com')
      ),
      OpenStruct.new(
        request_count: 230_456,
        request_limit: 100_000,
        account: Account.new(id: SecureRandom.uuid, name: 'Bar', slug: 'bar', plan: Plan.new(name: 'Enterprise'), billing: Billing.new(state: 'subscribed')),
        admin: User.new(first_name: 'Pete', last_name: 'Doe', email: 'pete@example.com')
        )
    ]
  end
end
