# frozen_string_literal: true

Rails.application.config.action_policy.tap do |config|
  config.controller_authorize_current_user = false
  config.channel_authorize_current_user    = false
  config.auto_inject_into_controller       = false
  config.auto_inject_into_channel          = false
end

# Lookup chain should fallback to nil policy.
ActionPolicy::LookupChain.chain << -> * { NilClassPolicy }

##
# Monkey patches for Action Policy.
module ActionPolicy
  module Behaviour
    ##
    # Remove memoization of authorization context. This allows us to use
    # authorized_scope() before authorize!() in controllers for nested
    # resources, e.g. /v1/licenses/:id/group.
    #
    # See: https://github.com/palkan/action_policy/issues/217
    def authorization_context = self.class.authorization_targets.each_with_object({}) { |(k, m), o| o[k] = send(m) }

    ##
    # Allow nil :record in authorize!() calls. Sometimes we want to explicitly
    # authorize nil for certain policies, e.g. License::GroupPolicy#update?.
    # This also drops logic for implicit :record, which we don't use.
    #
    # See: https://github.com/palkan/action_policy/issues/218
    def lookup_authorization_policy(record, **options) = policy_for(record:, **options)
  end
end
