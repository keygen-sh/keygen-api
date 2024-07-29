# frozen_string_literal: true

class NullBilling < NullObject
  def subscribed? = true
  def canceled?   = false
  def trialing?   = false
  def active?     = true
  def card        = nil
end
