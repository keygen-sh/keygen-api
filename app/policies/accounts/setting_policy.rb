# frozen_string_literal: true

module Accounts
  class SettingPolicy < ApplicationPolicy
    scope_for :active_record_relation do |relation|
      case bearer
      in role: Role(:admin | :developer)
        relation.all
      else
        relation.none
      end
    end

    def index?
      verify_permissions!('account.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: Role(:admin | :developer)
        allow!
      else
        deny!
      end
    end

    def show?
      verify_permissions!('account.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: Role(:admin | :developer)
        allow!
      else
        deny!
      end
    end

    def create?
      verify_permissions!('account.update')
      verify_environment!

      case bearer
      in role: Role(:admin | :developer)
        allow!
      else
        deny!
      end
    end

    def update?
      verify_permissions!('account.update')
      verify_environment!

      case bearer
      in role: Role(:admin | :developer)
        allow!
      else
        deny!
      end
    end

    def destroy?
      verify_permissions!('account.update')
      verify_environment!

      case bearer
      in role: Role(:admin | :developer)
        allow!
      else
        deny!
      end
    end
  end
end
