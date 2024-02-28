# frozen_string_literal: true

# heroku run:detached --tail \
#   rails runner db/scripts/seed_machine_uniqueness_strategy_for_policies_script.rb

count = Policy.where(machine_uniqueness_strategy: nil)
              .update_all(<<~SQL)
                machine_uniqueness_strategy = fingerprint_uniqueness_strategy
              SQL

Rails.logger.info "Seeded #{count} policies"
