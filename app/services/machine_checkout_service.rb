class MachineCheckoutService < BaseService
  ALLOWED_INCLUDES = %w[
    entitlements
    product
    policy
    group
    license
    user
  ]

  def initialize(machine:, includes: [])
  end

  def call
  end
end
