# frozen_string_literal: true

class NullPlan < NullObject
  def name  = 'Null'

  def request_log_retention_duration? = false
  def request_log_retention_duration  = nil

  def event_log_retention_duration? = false
  def event_log_retention_duration  = nil

  def max_products = nil
  def max_policies = nil
  def max_licenses = nil
  def max_users    = nil
  def max_admins   = nil
  def max_reqs     = nil
  def max_storage  = nil
  def max_transfer = nil
  def max_upload   = nil

  def free? = false
  def paid? = true
  def ent?  = true
  def price = 0
end
