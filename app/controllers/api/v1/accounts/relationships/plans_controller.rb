# frozen_string_literal: true

module Api::V1::Accounts::Relationships
  class PlansController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :authenticate!

    def show
      plan = current_account.plan
      authorize! plan,
        with: Accounts::PlanPolicy

      render jsonapi: plan
    end

    typed_params {
      format :jsonapi

      param :data, type: :hash do
        param :type, type: :string, inclusion: { in: %w[plan plans] }
        param :id, type: :uuid
      end
    }
    def update
      plan = Plan.find(plan_params[:id])
      authorize! plan,
        with: Accounts::PlanPolicy

      status = if current_account.billing.canceled?
                 Billings::CreateSubscriptionService.call(
                   customer: current_account.billing.customer_id,
                   plan: plan.plan_id,
                   trial_end: 'now',
                 )
               else
                 Billings::UpdateSubscriptionService.call(
                   subscription: current_account.billing.subscription_id,
                   plan: plan.plan_id,
                 )
               end

      if status
        if current_account.billing.update(state: :pending) &&
           current_account.update(plan:)
          BroadcastEventService.call(
            event: 'account.plan.updated',
            account: current_account,
            resource: plan,
          )

          render jsonapi: plan
        else
          render_unprocessable_resource current_account
        end
      else
        if current_account.billing.card.present?
          render_unprocessable_entity detail: "failed to update #{current_account.billing.state} plan because of a billing issue (check payment method)"
        else
          render_unprocessable_entity detail: "failed to update plan because a payment method is missing"
        end
      end
    end
  end
end
