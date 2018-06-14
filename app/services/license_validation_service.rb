class LicenseValidationService < BaseService

  def initialize(license:, scope: nil)
    @license = license
    @scope   = scope
  end

  def execute
    return [false, "does not exist", :NOT_FOUND] if license.nil?
    # Check if license is suspended
    return [false, "is suspended", :SUSPENDED] if license.suspended?
    # Check if license is expired (move along if it has no expiry)
    return [false, "is expired", :EXPIRED] if license.expired?
    # Check if license is overdue for check in
    return [false, "is overdue for check in", :OVERDUE] if license.check_in_overdue?
    # Scope validations (quick validation skips this by setting explicitly to false)
    if scope != false
      # Check against product scope requirements
      if scope.present? && scope.key?(:product)
        return [false, "product scope does not match", :PRODUCT_SCOPE_MISMATCH] if license.product.id != scope[:product]
      else
        return [false, "product scope is required", :PRODUCT_SCOPE_REQUIRED] if license.policy.require_product_scope?
      end
      # Check against policy scope requirements
      if scope.present? && scope.key?(:policy)
        return [false, "policy scope does not match", :POLICY_SCOPE_MISMATCH] if license.policy.id != scope[:policy]
      else
        return [false, "policy scope is required", :POLICY_SCOPE_REQUIRED] if license.policy.require_policy_scope?
      end
      # Check against machine scope requirements
      if scope.present? && scope.key?(:machine)
        case
        when !license.policy.floating? && license.machines.count == 0
          return [false, "has no associated machine", :NO_MACHINE]
        when license.policy.floating? && license.machines.count == 0
          return [false, "has no associated machines", :NO_MACHINES]
        else
          return [false, "machine scope does not match", :MACHINE_SCOPE_MISMATCH] if !license.machines.exists?(scope[:machine])
        end
      else
        return [false, "machine scope is required", :MACHINE_SCOPE_REQUIRED] if license.policy.require_machine_scope?
      end
      # Check agaisnt fingerprint scope requirements
      if scope.present? && scope.key?(:fingerprint)
        case
        when !license.policy.floating? && license.machines.count == 0
          return [false, "has no associated machine", :NO_MACHINE]
        when license.policy.floating? && license.machines.count == 0
          return [false, "has no associated machines", :NO_MACHINES]
        else
          return [false, "fingerprint scope does not match", :FINGERPRINT_SCOPE_MISMATCH] if license.machines.fingerprint(scope[:fingerprint]).empty?
        end
      else
        return [false, "fingerprint scope is required", :FINGERPRINT_SCOPE_REQUIRED] if license.policy.require_fingerprint_scope?
      end
    end
    # Check if license policy is strict, e.g. enforces reporting of machine usage (and exit early if not strict)
    return [true, "is valid", :VALID] if !license.policy.strict?
    # Check if license policy allows floating and if not, should have single activation
    return [false, "must have exactly 1 associated machine", :NO_MACHINE] if !license.policy.floating? && license.machines.count == 0
    # When not floating, license's machine count should not surpass 1
    return [false, "has too many associated machines", :TOO_MANY_MACHINES] if !license.policy.floating? && license.machines.count > 1
    # When floating, license should have at least 1 activation
    return [false, "must have at least 1 associated machine", :NO_MACHINES] if license.policy.floating? && license.machines.count == 0
    # When floating, license's machine count should not surpass what policy allows
    return [false, "has too many associated machines", :TOO_MANY_MACHINES] if license.policy.floating? && !license.policy.max_machines.nil? && license.machines.count > license.policy.max_machines
    # All good
    return [true, "is valid", :VALID]
  end

  private

  attr_reader :license, :scope
end
