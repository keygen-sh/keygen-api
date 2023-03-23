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

    # Check if license's user has been banned
    return [false, "is banned", :BANNED] if
      license.banned?

    # Check if license is suspended
    return [false, "is suspended", :SUSPENDED] if license.suspended?

    # When revoking access, first check if license is expired (i.e. higher precedence)
    return [false, "is expired", :EXPIRED] if
      license.revoke_access? &&
      license.expired?

    # Check if license is overdue for check in
    return [false, "is overdue for check in", :OVERDUE] if license.check_in_overdue?
    # Scope validations (quick validation skips this by setting explicitly to false)
    if scope != false
      # Check against environment scope requirements
      if scope.present? && scope.key?(:environment)
        return [false, "environment scope does not match", :ENVIRONMENT_SCOPE_MISMATCH] unless
          license.environment&.code == scope[:environment] ||
          license.environment&.id == scope[:environment]
      else
        return [false, "environment scope is required", :ENVIRONMENT_SCOPE_REQUIRED] if
          license.policy.require_environment_scope?
      end

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

      # Check against :user scope requirements
      if scope.present? && scope.key?(:user)
        return [false, "user scope does not match", :USER_SCOPE_MISMATCH] unless
          license.user&.email == scope[:user] ||
          license.user&.id == scope[:user]
      else
        return [false, "user scope is required", :USER_SCOPE_REQUIRED] if
          license.policy.require_user_scope?
      end

      # Check against entitlement scope requirements
      if scope.present? && scope.key?(:entitlements)
        entitlements = scope[:entitlements].uniq

        return [false, "entitlements scope is empty", :ENTITLEMENTS_SCOPE_EMPTY] if
          entitlements.empty?

        return [false, "is missing one or more required entitlements", :ENTITLEMENTS_MISSING] if
          license.entitlements.where(code: entitlements).count != entitlements.size
      end

      # Check against machine scope requirements
      if scope.present? && scope.key?(:machine)
        case
        when !license.policy.floating? && license.machines_count == 0
          return [false, "machine is not activated (has no associated machine)", :NO_MACHINE]
        when license.policy.floating? && license.machines_count == 0
          return [false, "machine is not activated (has no associated machines)", :NO_MACHINES]
        else
          machine = license.machines.find_by(id: scope[:machine])

          return [false, "machine is not activated (does not match any associated machines)", :MACHINE_SCOPE_MISMATCH] unless
            machine.present?

          return [false, 'machine heartbeat is required', :HEARTBEAT_NOT_STARTED] if
            license.policy.require_heartbeat? &&
            machine.heartbeat_not_started?

          return [false, "machine heartbeat is dead", :HEARTBEAT_DEAD] if
            machine.dead?
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

        case
        when !license.policy.floating? && license.machines_count == 0
          return [false, "fingerprint is not activated (has no associated machine)", :NO_MACHINE]
        when license.policy.floating? && license.machines_count == 0
          return [false, "fingerprint is not activated (has no associated machines)", :NO_MACHINES]
        else
          return [false, 'machine heartbeat is dead', :HEARTBEAT_DEAD] if
            license.machines.dead.with_fingerprint(fingerprints).count == fingerprints.size

          machines = license.machines.with_fingerprint(fingerprints)
                                     .alive

          case
          when license.policy.fingerprint_match_most?
            return [false, "fingerprint is not activated (does not match enough associated machines)", :FINGERPRINT_SCOPE_MISMATCH] if
              machines.count < (fingerprints.size / 2.0).ceil
          when license.policy.fingerprint_match_all?
            return [false, "fingerprint is not activated (does not match all associated machines)", :FINGERPRINT_SCOPE_MISMATCH] if
              machines.count < fingerprints.size
          else
            return [false, "fingerprint is not activated (does not match any associated machines)", :FINGERPRINT_SCOPE_MISMATCH] if
              machines.empty?
          end

          return [false, 'machine heartbeat is required', :HEARTBEAT_NOT_STARTED] if
            license.policy.require_heartbeat? &&
            machines.any?(&:not_started?)
        end
      else
        return [false, "fingerprint scope is required", :FINGERPRINT_SCOPE_REQUIRED] if license.policy.require_fingerprint_scope?
      end
    end

    # Check if license policy is strict, e.g. enforces reporting of machine usage (and exit early if not strict).
    if !license.policy.strict?
      # Check if license is expired after checking machine requirements.
      return [license.allow_access?, "is expired", :EXPIRED] if
        license.expired?

      return [true, "is valid", :VALID]
    end

    # Check if license policy allows floating and if not, should have single activation
    return [false, "must have exactly 1 associated machine", :NO_MACHINE] if
      !license.policy.floating? && license.machines_count == 0

    # When not floating, license's machine count should not surpass 1
    if !license.policy.floating? && license.machines_count > 1
      allow_overage = license.always_allow_overage? ||
                      (license.allow_2x_overage? && license.machines_count == 2)

      return [allow_overage, "has too many associated machines", :TOO_MANY_MACHINES]
    end

    # When floating, license should have at least 1 activation
    return [false, "must have at least 1 associated machine", :NO_MACHINES] if
      license.policy.floating? && license.machines_count == 0

    # When floating, license's machine count should not surpass what policy allows
    if license.floating? && !license.max_machines.nil? && license.machines_count > license.max_machines
      allow_overage = license.always_allow_overage? ||
                      (license.allow_1_25x_overage? && license.machines_count <= license.max_machines * 1.25) ||
                      (license.allow_1_5x_overage? && license.machines_count <= license.max_machines * 1.5) ||
                      (license.allow_2x_overage? && license.machines_count <= license.max_machines * 2)

      return [allow_overage, "has too many associated machines", :TOO_MANY_MACHINES]
    end

    # Check if license has exceeded its CPU core limit
    if !license.max_cores.nil? && !license.machines_core_count.nil? && license.machines_core_count > license.max_cores
      allow_overage = license.always_allow_overage? ||
                      (license.allow_1_25x_overage? && license.machines_core_count <= license.max_cores * 1.25) ||
                      (license.allow_1_5x_overage? && license.machines_core_count <= license.max_cores * 1.5) ||
                      (license.allow_2x_overage? && license.machines_core_count <= license.max_cores * 2)

      return [allow_overage, "has too many associated machine cores", :TOO_MANY_CORES]
    end

    # Check if license has exceeded its process limit
    if license.max_processes.present?
      process_count = 0
      process_limit = 0

      case
      when license.lease_per_machine? && scope.present? && (scope.key?(:fingerprint) || scope.key?(:fingerprints))
        machine = license.machines.alive.find_by(
          fingerprint: Array(scope[:fingerprint] || scope[:fingerprints])
                         .compact
                         .uniq,
        )

        process_count = machine.processes.count
        process_limit = machine.max_processes
      when license.lease_per_machine? && scope.present? && scope.key?(:machine)
        machine = license.machines.alive.find_by(id: scope[:machine])

        process_count = machine.processes.count
        process_limit = machine.max_processes
      when license.lease_per_license?
        process_count = license.processes.count
        process_limit = license.max_processes
      end

      allow_overage = license.always_allow_overage? ||
                      (license.allow_1_25x_overage? && process_count <= process_limit * 1.25) ||
                      (license.allow_1_5x_overage? && process_count <= process_limit * 1.5) ||
                      (license.allow_2x_overage? && process_count <= process_limit * 2)

      return [allow_overage, "has too many associated processes", :TOO_MANY_PROCESSES] if
        process_count > process_limit
    end

    # Check if license is expired after checking machine requirements.
    return [license.allow_access?, "is expired", :EXPIRED] if
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
