# frozen_string_literal: true

# heroku run:detached --tail \
#   rails runner db/scripts/add_default_component_matching_strategy_to_policies_script.rb

count = Policy.where(component_matching_strategy: nil)
              .update_all(
                component_matching_strategy: 'MATCH_ANY'
              )

Rails.logger.info "Updated #{count} policies"
