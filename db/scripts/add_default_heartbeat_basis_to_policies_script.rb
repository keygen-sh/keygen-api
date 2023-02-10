# frozen_string_literal: true

# heroku run:detached --tail \
#   rails runner db/scripts/add_default_heartbeat_basis_to_policies_script.rb

total = 0
count = Policy.joins(:account).where(account: { api_version: %w[1.0 1.1 1.2] })
                              .update_all(
                                heartbeat_basis: 'FROM_FIRST_PING',
                              )

Rails.logger.info "Set #{count} legacy policies to FROM_FIRST_PING"

total += count
count = Policy.joins(:account).where(account: { api_version: %w[1.3] })
                              .where(require_heartbeat: false)
                              .update_all(
                                heartbeat_basis: 'FROM_FIRST_PING',
                              )

Rails.logger.info "Set #{count} policies to FROM_FIRST_PING"

total += count
count = Policy.joins(:account).where(account: { api_version: %w[1.3] })
                              .where(require_heartbeat: true)
                              .update_all(
                                heartbeat_basis: 'FROM_CREATION',
                              )

Rails.logger.info "Set #{count} policies to FROM_CREATION"

total += count

Rails.logger.info "Set #{total}/#{Policy.count} policies"
