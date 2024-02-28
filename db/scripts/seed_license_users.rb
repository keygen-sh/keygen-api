# frozen_string_literal: true

# heroku run:detached -e SLEEP_DURATION=0.5 --tail \
#   rails runner db/scripts/seed_license_users.rb

SLEEP_DURATION = ENV.fetch('SLEEP_DURATION') { 1 }.to_f

licenses = License.where_assoc_not_exists(:license_users)
                  .where_assoc_exists(:user)
                  .includes(:user)

Rails.logger.info "Seeding #{licenses.count} license_users"

licenses.find_each do |license|
  Rails.logger.info "Seeding license_user for license=#{license.id} <> user=#{license.user_id}"

  license.users << license.user

  sleep SLEEP_DURATION
end

Rails.logger.info "Done"
