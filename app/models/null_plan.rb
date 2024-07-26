# frozen_string_literal: true

class NullPlan < NullAssociation::NullObject
  def name  = 'Null'
  def free? = false
  def paid? = true
  def ent?  = true
end
