# frozen_string_literal: true

class NullObject
  def present? = false
  def blank?   = true
  def nil?     = true
end
