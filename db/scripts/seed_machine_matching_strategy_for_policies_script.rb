# frozen_string_literal: true

# heroku run:detached --tail \
#   rails runner db/scripts/seed_machine_matching_strategy_for_policies_script.rb

count = Policy.where(machine_matching_strategy: nil)
              .update_all(<<~SQL)
                machine_matching_strategy = fingerprint_matching_strategy
              SQL

Rails.logger.info "Seeded #{count} policies"
