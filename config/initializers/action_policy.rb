# frozen_string_literal: true

Rails.application.config.action_policy.tap do |config|
  config.controller_authorize_current_user = false
  config.channel_authorize_current_user    = false
  config.auto_inject_into_controller       = false
  config.auto_inject_into_channel          = false
end

# Lookup chain should fallback to nil policy.
ActionPolicy::LookupChain.chain << -> * { NilClassPolicy }
