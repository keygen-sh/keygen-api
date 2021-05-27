class AnalyticsPolicy < Struct.new(:context, :resource)
  def read?
    bearer.has_role?(:admin, :developer)
  end

  private

  def bearer
    context.bearer
  end
end
