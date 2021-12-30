# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:all) do
    Rails.cache.clear(namespace: "test_#{ENV['TEST_ENV_NUMBER']}")
  end

  config.after(:each) do
    Rails.cache.clear(namespace: "test_#{ENV['TEST_ENV_NUMBER']}")
  end
end
