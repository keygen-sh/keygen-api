class LicenseValidationService < BaseService

  def initialize(license:)
    @license = license
  end

  def execute
    return [false, "does not exist"] if license.nil?
    # Check if license is suspended
    return [false, "is suspended"] if license.suspended?
    # Check if license is expired (move along if it has no expiry)
    return [false, "is expired"] if !license.expiry.nil? && license.expiry < Time.current
    # Check if license policy is strict, e.g. enforces reporting of machine usage
    return [true, "is valid"] if !license.policy.strict?
    # Check if license policy allows floating and if not, should have single activation
    return [true, "is valid"] if !license.policy.floating? && license.machines.count == 1
    # Assume floating, should have at least 1 activation but no more than policy allows
    return [true, "is valid"] if license.policy.floating? && license.machines.count >= 1 && !policy.max_machines.nil? && license.machines.count <= license.policy.max_machines
    # Otherwise, assume invalid
    return [false, "does not meet machine requirements"]
  end

  private

  attr_reader :license
end
