# frozen_string_literal: true

module Stdin
  class SendgridController < ApplicationController
    def receive_webhook
      fingerprint, token = from_address.split('@').first.split('+')
      license_id, action = to_address.split('@').first.split('+')

      puts message_id: message_id,
           to: to_address,
           from: from_address,
           license_id: license_id,
           action: action,
           fingerprint: fingerprint,
           token: token,
           body: body

      license = FindByAliasService.call(scope: License, identifier: license_id, aliases: :key)

      @current_account = license.account

      if token.present?
        @current_token  = TokenAuthenticationService.call(account: current_account, token: token)
        @current_bearer = current_token.bearer
      end

      case action
      when 'validate'
        validate!(license, fingerprint)
      when 'activate'
        activate!(license, fingerprint)
      when 'deactivate'
        deactivate!(license, fingerprint)
      when 'ping'
        ping!(license, fingerprint)
      end
    rescue ActiveRecord::RecordNotFound,
           ActiveRecord::RecordInvalid,
           Pundit::NotAuthorizedError
      # noop
    rescue => e
      Keygen.logger.exception(e)
    ensure
      skip_authorization

      head :accepted
    end

    private

    def validate!(license, fingerprint)
      # authorize license, :validate?

      ok, msg, code = LicenseValidationService.call(license: license, scope: { fingerprint: fingerprint })
      meta = { ts: Time.current, valid: ok, detail: msg, constant: code }

      BroadcastEventService.call(
        event: ok ? 'license.validation.succeeded' : 'license.validation.failed',
        account: current_account,
        resource: license,
        meta: meta
      )
    end

    def activate!(license, fingerprint)
      machine = license.machines.new(account: current_account, license: license, fingerprint: fingerprint)
      # authorize machine, :activate?

      machine.save!

      BroadcastEventService.call(event: 'machine.created', account: current_account, resource: machine)
    end

    def deactivate!(license, fingerprint)
      machine = FindByAliasService.call(scope: license.machines, identifier: fingerprint, aliases: :fingerprint)
      # authorize machine, :deactivate?

      machine.destroy!

      BroadcastEventService.call(event: 'machine.deleted', account: current_account, resource: machine)
    end

    def ping!(license, fingerprint)
      machine = FindByAliasService.call(scope: license.machines, identifier: fingerprint, aliases: :fingerprint)
      # authorize machine, :ping?

      return if
        machine.heartbeat_dead?

      machine.update!(last_heartbeat_at: Time.current)

      BroadcastEventService.call(event: 'machine.heartbeat.ping', account: current_account, resource: machine)

      MachineHeartbeatWorker.perform_in(
        machine.heartbeat_duration + Machine::HEARTBEAT_DRIFT,
        machine.id,
      )
    end

    def mail
      @mail ||= Mail.new(params['email'])
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
      params['sender_ip']
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
