# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each) { Rails.cache.clear }
  config.after(:all)   { Rails.cache.clear }
end
