# frozen_string_literal: true

# heroku run:detached --tail \
#   rails runner db/scripts/seed_renewal_basis_for_policies_script.rb

count = Policy.where(renewal_basis: nil)
              .update_all(
                renewal_basis: 'FROM_EXPIRY',
              )

Rails.logger.info "Seeded #{count} policies"
