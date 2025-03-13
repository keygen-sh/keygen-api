# frozen_string_literal: true

require_relative 'ee/license_file'
require_relative 'ee/license'
require_relative 'ee/protected_methods'
require_relative 'ee/protected_class'
require_relative 'ee/router'
require_relative 'ee/sso'

module Keygen
  module EE
    def self.license_file = LicenseFile.current
    def self.license      = License.current
  end

  ActionDispatch::Routing::Mapper.send(:include, EE::Router)
end
