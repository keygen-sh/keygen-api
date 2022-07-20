class AnalyticsPolicy < Struct.new(:context, :resource)
  def read?
    bearer.has_role?(:admin, :developer, :read_only)
  end

  private

  def account = context.bearer
  def bearer  = context.bearer
  def token   = context.token
end
