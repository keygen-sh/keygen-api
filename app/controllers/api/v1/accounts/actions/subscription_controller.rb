# frozen_string_literal: true

module Api::V1::Accounts::Actions
  class SubscriptionController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :authenticate!

    def manage
      authorize! with: Accounts::SubscriptionPolicy

      session = Billings::CreateBillingPortalSessionService.call(customer: current_account.billing.customer_id)
      if session
        headers['Location'] = session.url

        render_meta url: session.url
      else
        render_unprocessable_entity detail: 'failed to generate a subscription management session'
      end
    end

    def pause
      authorize! with: Accounts::SubscriptionPolicy

      if current_account.pause_subscription!
        BroadcastEventService.call(
          event: 'account.subscription.paused',
          account: current_account,
          resource: current_account,
        )

        render_no_content
      else
        render_unprocessable_entity detail: "failed to pause #{current_account.billing.state} subscription"
      end
    end

    def resume
      authorize! with: Accounts::SubscriptionPolicy

      if current_account.resume_subscription!
        BroadcastEventService.call(
          event: 'account.subscription.resumed',
          account: current_account,
          resource: current_account,
        )

        render_no_content
      else
        render_unprocessable_entity detail: "failed to resume #{current_account.billing.state} subscription"
      end
    end

    def cancel
      authorize! with: Accounts::SubscriptionPolicy

      if current_account.cancel_subscription_at_period_end!
        BroadcastEventService.call(
          event: 'account.subscription.canceled',
          account: current_account,
          resource: current_account,
        )

        render_no_content
      else
        render_unprocessable_entity detail: "failed to cancel #{current_account.billing.state} subscription"
      end
    end

    def renew
      authorize! with: Accounts::SubscriptionPolicy

      if current_account.renew_subscription!
        BroadcastEventService.call(
          event: 'account.subscription.renewed',
          account: current_account,
          resource: current_account,
        )

        render_no_content
      else
        render_unprocessable_entity detail: "failed to renew #{current_account.billing.state} subscription"
      end
    end
  end
end
