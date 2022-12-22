# frozen_string_literal: true

# heroku run:detached -e SLEEP_DURATION=0.5 --tail \
#   rails runner db/scripts/encrypt_license_keys_script.rb

SLEEP_DURATION = ENV.fetch('SLEEP_DURATION') { 1 }.to_f

License.find_each do |license|
  next if
    license.encrypted_attribute?(:key)

  license.encrypt

  sleep SLEEP_DURATION
end
