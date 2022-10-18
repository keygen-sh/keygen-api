# frozen_string_literal: true

require_relative 'ee/license_file'
require_relative 'ee/license'
require_relative 'ee/protected_record'
require_relative 'ee/router'

module Keygen
  module EE
    def self.license = License.current
  end

  ActionDispatch::Routing::Mapper.send(:include, EE::Router)
end
