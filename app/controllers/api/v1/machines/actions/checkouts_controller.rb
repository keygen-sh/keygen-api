# frozen_string_literal: true

module Api::V1::Machines::Actions
  class CheckoutsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_machine

    authorize :machine

    typed_query {
      param :encrypt, type: :boolean, coerce: true, optional: true
      param :algorithm, type: :string, allow_blank: true, optional: true
      param :ttl, type: :integer, coerce: true, allow_nil: true, optional: true
      param :include, type: :array, coerce: true, allow_blank: true, optional: true, transform: -> key, includes {
        # FIXME(ezekg) For backwards compatibility. Replace license.user include with
        #              license.owner when present.
        includes.push('license.owner') if includes.delete('license.user')

        [key, includes]
      }
    }
    def show
      kwargs = checkout_query.slice(
        :algorithm,
        :include,
        :encrypt,
        :ttl,
      )

      machine_file = checkout_machine_file(**kwargs)

      response.headers['Content-Disposition'] = %(attachment; filename="#{machine.id}.lic")
      response.headers['Content-Type']        = 'application/octet-stream'

      render body: machine_file.certificate
    rescue MachineCheckoutService::InvalidAlgorithmError => e
      render_bad_request detail: e.message, code: :CHECKOUT_ALGORITHM_INVALID, source: { parameter: :algorithm }
    rescue MachineCheckoutService::InvalidIncludeError => e
      render_bad_request detail: e.message, code: :CHECKOUT_INCLUDE_INVALID, source: { parameter: :include }
    rescue MachineCheckoutService::InvalidTTLError => e
      render_bad_request detail: e.message, code: :CHECKOUT_TTL_INVALID, source: { parameter: :ttl }
    rescue MachineCheckoutService::InvalidAlgorithmError => e
      render_unprocessable_entity detail: e.message
    end

    typed_params {
      format :jsonapi

      param :meta, type: :hash, optional: true do
        param :encrypt, type: :boolean, optional: true
        param :algorithm, type: :string, allow_blank: true, allow_nil: true, optional: true
        param :ttl, type: :integer, coerce: true, allow_nil: true, optional: true
        param :include, type: :array, allow_blank: true, optional: true, transform: -> key, includes {
          includes.push('license.owner') if includes.delete('license.user')

          [key, includes]
        }
      end
    }
    typed_query {
      param :encrypt, type: :boolean, coerce: true, optional: true
      param :algorithm, type: :string, allow_blank: true, optional: true
      param :ttl, type: :integer, coerce: true, allow_nil: true, optional: true
      param :include, type: :array, coerce: true, allow_blank: true, optional: true, transform: -> key, includes {
        includes.push('license.owner') if includes.delete('license.user')

        [key, includes]
      }
    }
    def create
      kwargs = checkout_query.merge(checkout_meta)
                             .slice(
                               :algorithm,
                               :include,
                               :encrypt,
                               :ttl,
                             )

      machine_file = checkout_machine_file(**kwargs)

      render jsonapi: machine_file
    rescue MachineCheckoutService::InvalidAlgorithmError => e
      render_bad_request detail: e.message, code: :CHECKOUT_ALGORITHM_INVALID, source: { parameter: :algorithm }
    rescue MachineCheckoutService::InvalidIncludeError => e
      render_bad_request detail: e.message, code: :CHECKOUT_INCLUDE_INVALID, source: { parameter: :include }
    rescue MachineCheckoutService::InvalidTTLError => e
      render_bad_request detail: e.message, code: :CHECKOUT_TTL_INVALID, source: { parameter: :ttl }
    rescue MachineCheckoutService::InvalidAlgorithmError => e
      render_unprocessable_entity detail: e.message
    end

    private

    attr_reader :machine

    def set_machine
      scoped_machines = authorized_scope(current_account.machines).lazy_preload(
        components: %i[product license],
        license: {
          users: %i[role],
        },
      )

      @machine = FindByAliasService.call(scoped_machines, id: params[:id], aliases: :fingerprint)

      Current.resource = machine
    end

    def checkout_machine_file(**kwargs)
      authorize! machine,
        to: :check_out?

      machine_file = MachineCheckoutService.call(
        api_version: current_api_version,
        environment: current_environment,
        account: current_account,
        machine:,
        **kwargs,
      )
      authorize! machine_file,
        to: :show?

      machine_file.validate!
      machine.touch_async(:last_check_out_at,
        time: Time.current,
      )

      BroadcastEventService.call(
        event: 'machine.checked-out',
        account: current_account,
        resource: machine,
      )

      machine_file
    end
  end
end
