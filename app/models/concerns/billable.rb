module Billable
  extend ActiveSupport::Concern

  def active?
    billing&.external_status == "active"
  end

  def pending?
    billing&.external_status == "pending"
  end

  def trialing?
    billing&.external_status == "trialing"
  end

  def paused?
    billing&.external_status == "paused"
  end

  def canceled?
    billing&.external_status == "canceled"
  end
end
