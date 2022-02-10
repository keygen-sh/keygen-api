# frozen_string_literal: true

class LicenseValidationService < BaseService

  def initialize(license:, scope: nil, skip_touch: false)
    @license    = license
    @scope      = scope
    @skip_touch = skip_touch
  end

  def call
    return [false, "does not exist", :NOT_FOUND] if license.nil?

    touch_last_validated_at unless
      skip_touch?

    # Check if license is suspended
    return [false, "is suspended", :SUSPENDED] if license.suspended?

    # When revoking access, check if license is expired (move along if it has no expiry)
    return [false, "is expired", :EXPIRED] if
      license.revoke_access? &&
      license.expired?

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
        when !license.policy.floating? && license.machines_count == 0
          return [false, "machine is not activated (has no associated machine)", :NO_MACHINE]
        when license.policy.floating? && license.machines_count == 0
          return [false, "machine is not activated (has no associated machines)", :NO_MACHINES]
        else
          return [false, "machine heartbeat is dead", :HEARTBEAT_DEAD] if
            license.machines.dead.exists?(scope[:machine])

          return [false, "machine is not activated (does not match any associated machines)", :MACHINE_SCOPE_MISMATCH] unless
            license.machines.alive.exists?(scope[:machine])
        end
      else
        return [false, "machine scope is required", :MACHINE_SCOPE_REQUIRED] if license.policy.require_machine_scope?
      end
      # Check against fingerprint scope requirements
      if scope.present? && (scope.key?(:fingerprint) || scope.key?(:fingerprints))
        fingerprints = Array(scope[:fingerprint] || scope[:fingerprints])
                         .compact
                         .uniq

        return [false, "fingerprint scope is empty", :FINGERPRINT_SCOPE_EMPTY] if
          fingerprints.empty?

        return [false, 'machine heartbeat is dead', :HEARTBEAT_DEAD] if
          license.machines.dead.with_fingerprint(fingerprints).count == fingerprints.size

        case
        when !license.policy.floating? && license.machines_count == 0
          return [false, "fingerprint is not activated (has no associated machine)", :NO_MACHINE]
        when license.policy.floating? && license.machines_count == 0
          return [false, "fingerprint is not activated (has no associated machines)", :NO_MACHINES]
        else
          case
          when license.policy.fingerprint_match_most?
            return [false, "fingerprint is not activated (does not match enough associated machines)", :FINGERPRINT_SCOPE_MISMATCH] if
              license.machines.alive.with_fingerprint(fingerprints).count < (fingerprints.size / 2.0).ceil
          when license.policy.fingerprint_match_all?
            return [false, "fingerprint is not activated (does not match all associated machines)", :FINGERPRINT_SCOPE_MISMATCH] if
              license.machines.alive.with_fingerprint(fingerprints).count < fingerprints.size
          else
            return [false, "fingerprint is not activated (does not match any associated machines)", :FINGERPRINT_SCOPE_MISMATCH] if
              license.machines.alive.with_fingerprint(fingerprints).empty?
          end
        end
      else
        return [false, "fingerprint scope is required", :FINGERPRINT_SCOPE_REQUIRED] if license.policy.require_fingerprint_scope?
      end
      # Check against entitlement scope requirements
      if scope.present? && scope.key?(:entitlements)
        entitlements = scope[:entitlements].uniq

        return [false, "entitlements scope is empty", :ENTITLEMENTS_SCOPE_EMPTY] if entitlements.empty?

        return [false, "is missing one or more required entitlements", :ENTITLEMENTS_MISSING] if license.entitlements.where(code: entitlements).count != entitlements.size
      end
    end

    # Check if license policy is strict, e.g. enforces reporting of machine usage (and exit early if not strict).
    if !license.policy.strict?
      # When restricting access, check if license is expired after checking machine requirements.
      return [false, "is expired", :EXPIRED] if
        license.restrict_access? &&
        license.expired?

      return [true, "is valid", :VALID]
    end

    # Check if license policy allows floating and if not, should have single activation
    return [false, "must have exactly 1 associated machine", :NO_MACHINE] if !license.policy.floating? && license.machines_count == 0
    # When not floating, license's machine count should not surpass 1
    return [false, "has too many associated machines", :TOO_MANY_MACHINES] if !license.policy.floating? && license.machines_count > 1
    # When floating, license should have at least 1 activation
    return [false, "must have at least 1 associated machine", :NO_MACHINES] if license.policy.floating? && license.machines_count == 0
    # When floating, license's machine count should not surpass what policy allows
    return [false, "has too many associated machines", :TOO_MANY_MACHINES] if license.floating? && !license.max_machines.nil? && license.machines_count > license.max_machines
    # Check if license has exceeded its CPU core limit
    return [false, "has too many associated machine cores", :TOO_MANY_CORES] if !license.max_cores.nil? && !license.machines_core_count.nil? && license.machines_core_count > license.max_cores

    # When restricting access, check if license is expired after checking machine requirements.
    return [false, "is expired", :EXPIRED] if
        license.restrict_access? &&
        license.expired?

    # All good
    return [true, "is valid", :VALID]
  end

  private

  attr_reader :license, :scope

  def skip_touch?
    @skip_touch
  end

  def touch_last_validated_at
    return if
      skip_touch?

    # We're going to attempt to update the license's last validated timestamp,
    # but if there's a concurrent update then we'll skip.
    license.with_lock 'FOR UPDATE SKIP LOCKED' do
      license.last_validated_at = Time.current
      license.save!
    end
  rescue ActiveRecord::LockWaitTimeout, # For NOWAIT lock wait timeout error
         ActiveRecord::RecordNotFound   # SKIP LOCKED raises not found
    # noop
  rescue => e
    Keygen.logger.exception(e)
  end
end
