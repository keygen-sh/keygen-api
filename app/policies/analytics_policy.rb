class AnalyticsPolicy < Struct.new(:bearer, :resource)
  def read?
    bearer.has_role?(:admin, :developer)
  end
end