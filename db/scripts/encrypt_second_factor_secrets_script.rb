# frozen_string_literal: true

# heroku run:detached -e SLEEP_DURATION=0.5 --tail \
#   rails runner db/scripts/encrypt_second_factor_secrets_script.rb

SLEEP_DURATION = ENV.fetch('SLEEP_DURATION') { 0.1 }.to_f

SecondFactor.find_each do |second_factor|
  next if
    second_factor.encrypted_attribute?(:secret)

  second_factor.encrypt

  sleep SLEEP_DURATION
end
