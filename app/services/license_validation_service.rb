class LicenseValidationService < BaseService

  def initialize(license:)
    @license = license
  end

  def execute
    return [false, "does not exist"] if license.nil?
    # Check if license is overdue for check in
    return [false, "is overdue for check in"] if license.check_in_overdue?
    # Check if license is suspended
    return [false, "is suspended"] if license.suspended?
    # Check if license is expired (move along if it has no expiry)
    return [false, "is expired"] if license.expired?
    # Check if license policy is strict, e.g. enforces reporting of machine usage (and exit early if not strict)
    return [true, "is valid"] if !license.policy.strict?
    # Check if license policy allows floating and if not, should have single activation
    return [false, "must have exactly 1 associated machine"] if !license.policy.floating? && license.machines.count == 0
    # When not floating, license's machine count should not surpass 1
    return [false, "too many associated machines"] if !license.policy.floating? && license.machines.count > 1
    # When floating, license should have at least 1 activation
    return [false, "must have at least 1 associated machine"] if license.policy.floating? && license.machines.count == 0
    # When floating, license's machine count should not surpass what policy allows
    return [false, "too many associated machines"] if license.policy.floating? && license.machines.count > license.policy.max_machines
    # All good
    return [true, "is valid"]
  end

  private

  attr_reader :license
end
