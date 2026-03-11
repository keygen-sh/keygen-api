# frozen_string_literal: true

module Keygen
  module Routing
    class << self
      def url_helpers = Rails.application.routes.url_helpers

      def path_for(class_name, id: nil, account: nil)
        if id.present?
          singular_path_for(class_name, id, account:)
        else
          plural_path_for(class_name, account:)
        end
      end

      private

      def singular_path_for(class_name, id, account:)
        klass = class_name.safe_constantize
        return if
          klass.nil?

        reflection = Account.reflect_on_all_associations.find { it.klass == klass }
        route_key  = klass.model_name.singular_route_key

        case reflection&.macro
        in :belongs_to | :has_one unless account.nil?
          safe_route(:"v1_account_#{route_key}_path", account)
        in :has_many unless account.nil?
          safe_route(:"v1_account_#{route_key}_path", account, id)
        else
          safe_route(:"v1_#{route_key}_path", id)
        end
      end

      def plural_path_for(class_name, account:)
        klass = class_name.safe_constantize
        return if
          klass.nil?

        reflection = Account.reflect_on_all_associations.find { it.klass == klass }
        route_key  = klass.model_name.route_key

        case reflection&.macro
        in :has_many unless account.nil?
          safe_route(:"v1_account_#{route_key}_path", account)
        else
          safe_route(:"v1_#{route_key}_path")
        end
      end

      def safe_route(route_key, ...)
        return unless url_helpers.respond_to?(route_key)

        url_helpers.public_send(route_key, ...)
      end
    end
  end
end
