# frozen_string_literal: true

# heroku run:detached -e SLEEP_DURATION=0.5 --tail \
#   rails runner db/scripts/seed_license_users.rb

BATCH_SIZE     = ENV.fetch('BATCH_SIZE')     { 1_000 }.to_i
SLEEP_DURATION = ENV.fetch('SLEEP_DURATION') { 1 }.to_f

licenses_with_users = License.where_assoc_not_exists(:license_users)
                             .where_assoc_exists(:user)
                             .eager_load(
                               :account,
                               :user,
                             )

Rails.logger.info "Seeding license_users for #{licenses_with_users.count} total licenses"

licenses_with_users.find_in_batches(batch_size: BATCH_SIZE) do |licenses|
  Rails.logger.info "Seeding batch of #{licenses.count} licenses"

  licenses.each do |license|
    Rails.logger.info "Seeding license_user for license=#{license.id} <> user=#{license.user_id}"

    license.users << license.user
  end

  sleep SLEEP_DURATION
end

Rails.logger.info "Done"
