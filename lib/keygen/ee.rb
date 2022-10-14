# frozen_string_literal: true

require_relative 'ee/license_file'
require_relative 'ee/license'

module Keygen
  module EE
    def self.license = License.current
  end
end
