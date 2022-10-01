# heroku run:detached -e 'BATCH_SIZE=10000;SLEEP_DURATION=3' rails runner db/scripts/seed_permissions_for_roles.rb --tail

BATCH_SIZE     = ENV.fetch('BATCH_SIZE')     { 1_000 }.to_i
SLEEP_DURATION = ENV.fetch('SLEEP_DURATION') { 1 }.to_f

Rails.logger.info "[scripts.seed_permissions_for_roles] Starting"

roles       = Role.where.missing(:role_permissions)
batch_count = 0
role_count  = 0

Rails.logger.info "[scripts.seed_permissions_for_roles] Seeding #{roles.count} roles"

roles.find_in_batches(batch_size: BATCH_SIZE) do |batch|
  batch_count += 1

  Rails.logger.info "[scripts.seed_permissions_for_roles] Seeding batch ##{batch_count} of #{batch.size} roles"

  batch.each do |role|
    role_count += 1

    role.reset_permissions!
  end

  sleep SLEEP_DURATION
end

Rails.logger.info "[scripts.seed_permissions_for_roles] Seeded #{role_count} roles"

Rails.logger.info "[scripts.seed_permissions_for_roles] Done"
