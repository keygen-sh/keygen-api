# frozen_string_literal: true

module Accounts
  class SubscriptionPolicy < ApplicationPolicy
    def manage?
      verify_permissions!('account.subscription.update')

      case bearer
      in role: { name: 'admin' }
        allow!
      else
        deny!
      end
    end

    def pause?
      verify_permissions!('account.subscription.update')

      case bearer
      in role: { name: 'admin' }
        allow!
      else
        deny!
      end
    end

    def resume?
      verify_permissions!('account.subscription.update')

      case bearer
      in role: { name: 'admin' }
        allow!
      else
        deny!
      end
    end

    def cancel?
      verify_permissions!('account.subscription.update')

      case bearer
      in role: { name: 'admin' }
        allow!
      else
        deny!
      end
    end

    def renew?
      verify_permissions!('account.subscription.update')

      case bearer
      in role: { name: 'admin' }
        allow!
      else
        deny!
      end
    end
  end
end
