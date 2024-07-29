# frozen_string_literal: true

class NullPlan < NullObject
  def name         = 'Null'
  def price        = 0
  def max_products = nil
  def max_policies = nil
  def max_licenses = nil
  def max_users    = nil
  def max_admins   = nil
  def max_reqs     = nil
  def free?        = false
  def paid?        = true
  def ent?         = true
end
