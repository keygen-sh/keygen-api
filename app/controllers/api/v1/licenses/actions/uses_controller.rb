# frozen_string_literal: true

module Api::V1::Licenses::Actions
  class UsesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate!
    before_action :set_license

    authorize :license

    typed_params {
      format :jsonapi

      param :meta, type: :hash, optional: true do
        param :increment, type: :integer, optional: true
      end
    }
    def increment
      authorize! license,
        with: Licenses::UsagePolicy

      license.with_lock 'FOR UPDATE NOWAIT' do
        license.increment :uses, use_meta.fetch(:increment, 1)
        license.save!
      end

      BroadcastEventService.call(
        event: 'license.usage.incremented',
        account: current_account,
        resource: license,
      )

      render jsonapi: license
    rescue ActiveRecord::RecordNotSaved,
           ActiveRecord::RecordInvalid
      render_unprocessable_resource license
    rescue ActiveRecord::StaleObjectError,
           ActiveRecord::StatementInvalid # Thrown when update is attempted on locked row i.e. from FOR UPDATE NOWAIT
      render_conflict detail: 'failed to increment due to another conflicting update',
                      source: { pointer: '/data/attributes/uses' }
    rescue ActiveModel::RangeError
      render_bad_request detail: 'integer is too large',
                         source: { pointer: '/meta/increment' }
    end

    typed_params {
      format :jsonapi

      param :meta, type: :hash, optional: true do
        param :decrement, type: :integer, optional: true
      end
    }
    def decrement
      authorize! license,
        with: Licenses::UsagePolicy

      license.with_lock 'FOR UPDATE NOWAIT' do
        license.decrement :uses, use_meta.fetch(:decrement, 1)
        license.save!
      end

      BroadcastEventService.call(
        event: 'license.usage.decremented',
        account: current_account,
        resource: license,
      )

      render jsonapi: license
    rescue ActiveRecord::RecordNotSaved,
           ActiveRecord::RecordInvalid
      render_unprocessable_resource license
    rescue ActiveRecord::StaleObjectError,
           ActiveRecord::StatementInvalid
      render_conflict detail: 'failed to increment due to another conflicting update',
                      source: { pointer: '/data/attributes/uses' }
    rescue ActiveModel::RangeError
      render_bad_request detail: 'integer is too large',
                         source: { pointer: '/meta/decrement' }
    end

    def reset
      authorize! license,
        with: Licenses::UsagePolicy

      if license.update(uses: 0)
        BroadcastEventService.call(
          event: 'license.usage.reset',
          account: current_account,
          resource: license,
        )

        render jsonapi: license
      else
        render_unprocessable_resource license
      end
    end

    private

    attr_reader :license

    def set_license
      scoped_licenses = authorized_scope(current_account.licenses)

      @license = FindByAliasService.call(scoped_licenses, id: params[:id], aliases: :key)

      Current.resource = license
    end
  end
end
