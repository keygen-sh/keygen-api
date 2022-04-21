# frozen_string_literal: true

require_dependency Rails.root.join('lib', 'versionist')

Versionist.configure do |config|
  config.logger = Keygen.logger
end
