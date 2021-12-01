# frozen_string_literal: true

module Stdin
  class SendgridController < ApplicationController
    def receive_webhook
      id_action, to_host  = to_address.split('@')
      license_id, action  = id_action.split('+')

      id_token, from_host = from_address.split('@')
      machine_id, token   = id_action.split('+')

      license = FindByAliasService.call(scope: License, identifier: license_id, aliases: :key)

      @current_account = license.account
      @current_token   = TokenAuthenticationService.call(account: current_account, token: token)
      @current_bearer  = current_token.bearer

      case action
      when 'validate'
        authorize license, :validate?

        ok, msg, code = LicenseValidationService.call(license: license, scope: { fingerprint: machine_id })
        meta = { ts: Time.current, valid: ok, detail: msg, constant: code }

        BroadcastEventService.call(
          event: ok ? 'license.validation.succeeded' : 'license.validation.failed',
          account: current_account,
          resource: license,
          meta: meta
        )
      when 'activate'
        machine = license.machines.new(account: current_account, license: license)
        authorize machine, :activate?

        machine.save!

        BroadcastEventService.call(event: 'machine.created', account: current_account, resource: machine)
      when 'deactivate'
        machine = FindByAliasService.call(scope: license.machines, identifier: machine_id, aliases: :fingerprint)
        authorize machine, :deactivate?

        machine.destroy!

        BroadcastEventService.call(event: 'machine.deleted', account: current_account, resource: machine)
      when 'ping'
        machine = FindByAliasService.call(scope: license.machines, identifier: machine_id, aliases: :fingerprint)
        authorize machine, :ping?

        return if
          machine.heartbeat_dead?

        machine.update!(last_heartbeat_at: Time.current)

        MachineHeartbeatWorker.perform_in(
          machine.heartbeat_duration + Machine::HEARTBEAT_DRIFT,
          machine.id,
        )

        BroadcastEventService.call(event: 'machine.heartbeat.ping', account: current_account, resource: machine)
      end
    rescue Keygen::Error::NotFoundError
      # noop
    rescue => e
      Rails.logger.exception(e)
    ensure
      skip_authorization

      head :accepted
    end

    private

    def mail
      @mail ||= Mail.new(params.fetch(:email))
    end

    def message_id
      mail.message_id
    end

    def from_address
      mail.from.first
    end

    def to_address
      mail.to.first
    end

    def ip_address
      params.fetch(:sender_ip)
    end

    def plaintext_body
      mail.body.decoded
    end

    def body
      JSON.parse(plaintext_body.squish)
    rescue
      nil
    end
  end
end
