# frozen_string_literal: true

module Stdin
  class SendgridController < ApplicationController
    include TypedParameters::ControllerMethods

    before_action :set_current_account
    before_action :set_action_name
    before_action :set_params

    # NOTE(ezekg) These are both for typed params compat
    attr_accessor :action_name,
                  :params

    def receive_webhook
      case action_name
      when :validate
        license = FindByAliasService.call(scope: current_account.licenses, identifier: sendgrid_params[:id], aliases: :key)
        # authorize license, :validate?

        ok, msg, code = LicenseValidationService.call(license: license, scope: sendgrid_meta[:scope])
        meta = { ts: Time.current, valid: ok, detail: msg, constant: code }

        BroadcastEventService.call(
          event: ok ? 'license.validation.succeeded' : 'license.validation.failed',
          account: current_account,
          resource: license,
          meta: meta
        )
      when :activate
        machine = current_account.machines.new(sendgrid_params)
        # authorize machine, :activate?

        machine.save!

        BroadcastEventService.call(event: 'machine.created', account: current_account, resource: machine)
      when :deactivate
        machine = FindByAliasService.call(scope: current_account.machines, identifier: sendgrid_params[:id], aliases: :fingerprint)
        # authorize machine, :deactivate?

        machine.destroy!

        BroadcastEventService.call(event: 'machine.deleted', account: current_account, resource: machine)
      when :ping
        machine = FindByAliasService.call(scope: current_account.machines, identifier: sendgrid_params[:id], aliases: :fingerprint)
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

    attr_reader :license

    def set_current_account
      account_id = mail.to.first.split('@')
                          .first.split('+')
                          .first

      @current_account = FindByAliasService.call(scope: Account, identifier: account_id, aliases: :slug)
    end

    def set_action_name
      @action_name = mail.to.first.split('@')
                            .first.split('+')
                            .second
                            .to_sym
    end

    def set_params
      body = if !mail.content_type.start_with?('text/plain')
               body = mail.parts.find { |p| p.content_type.start_with?('text/plain') }
             else
               body = mail.body
             end

      @params = JSON.parse(body.decoded.squish)
    end

    def mail
      @mail ||= Mail.new(request.params['email'])
    end

    typed_parameters format: :jsonapi do
      options strict: false

      on :validate do
        param :meta, type: :hash, optional: true do
          param :scope, type: :hash, optional: true do
            param :product, type: :string, optional: true
            param :policy, type: :string, optional: true
            param :machine, type: :string, optional: true
            param :fingerprint, type: :string, optional: true
            param :fingerprints, type: :array, optional: true do
              items type: :string
            end
            param :entitlements, type: :array, optional: true do
              items type: :string
            end
          end
        end
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[license licenses]
          param :id, type: :string
        end
      end

      on :activate do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[machine machines]
          param :attributes, type: :hash do
            param :fingerprint, type: :string
            param :name, type: :string, optional: true, allow_nil: true
            param :ip, type: :string, optional: true, allow_nil: true
            param :hostname, type: :string, optional: true, allow_nil: true
            param :platform, type: :string, optional: true, allow_nil: true
            param :cores, type: :integer, optional: true, allow_nil: true
            param :metadata, type: :hash, allow_non_scalars: true, optional: true
          end
          param :relationships, type: :hash do
            param :license, type: :hash do
              param :data, type: :hash do
                param :type, type: :string, inclusion: %w[license licenses]
                param :id, type: :string
              end
            end
          end
        end
      end

      on :deactivate do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[machine machines]
          param :id, type: :string
        end
      end

      on :ping do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[machine machines]
          param :id, type: :string
        end
      end
    end
  end
end
