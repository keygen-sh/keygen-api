module Api::V1::Accounts::Relationships
  class PlansController < Api::V1::BaseController
    before_action :authenticate_with_token!
    before_action :set_account

    # GET /accounts/1/plan
    def show
      authorize @account
      @plan = @account.plan

      render jsonapi: @plan
    end

    # PUT /accounts/1/plan
    def update
      authorize @account

      @plan = Plan.find plan_params[:id]

      status = if @account.plan.plan_id == "beta"
                 # TODO: Remove this logic after beta. Stripe doesn't let us go
                 #       from a free plan a trial without a card, so we need to
                 #       cancel the beta plan *and then* subscribe.
                 @account.cancel_subscription!

                 Billings::CreateSubscriptionService.new(
                   customer: @account.billing.customer_id,
                   plan: @plan.plan_id
                 ).execute
               elsif @account.billing.canceled?
                 Billings::CreateSubscriptionService.new(
                   customer: @account.billing.customer_id,
                   plan: @plan.plan_id
                 ).execute
               else
                 Billings::UpdateSubscriptionService.new(
                   subscription: @account.billing.subscription_id,
                   plan: @plan.plan_id
                 ).execute
               end

      if status
        if @account.update(plan: @plan)
          CreateWebhookEventService.new(
            event: "account.plan.updated",
            account: @account,
            resource: @plan
          ).execute

          render jsonapi: @plan
        else
          render_unprocessable_resource @account
        end
      else
        render_unprocessable_entity(
          detail: "failed to update #{@account.billing.state} subscription",
          source: { pointer: "/data/relationships/billing" }
        )
      end
    end

    private

    def set_account
      @account = Account.find params[:account_id]
    end

    typed_parameters transform: true do
      options strict: true

      on :update do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[plan plans]
          param :id, type: :string
        end
      end
    end
  end
end
