module Billable
  extend ActiveSupport::Concern

  def active?
    billing&.external_subscription_status == "active"
  end

  def pending?
    billing&.external_subscription_status == "pending"
  end

  def trialing?
    billing&.external_subscription_status == "trialing"
  end

  def paused?
    billing&.external_subscription_status == "paused"
  end

  def canceled?
    billing&.external_subscription_status == "canceled"
  end
end
