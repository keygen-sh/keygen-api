# frozen_string_literal: true

# heroku run:detached --tail \
#   rails runner db/scripts/add_default_component_uniqueness_strategy_to_policies_script.rb

count = Policy.where(component_uniqueness_strategy: nil)
              .update_all(
                component_uniqueness_strategy: 'UNIQUE_PER_MACHINE'
              )

Rails.logger.info "Updated #{count} policies"
