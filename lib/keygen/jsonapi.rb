# frozen_string_literal: true

require_relative 'jsonapi/renderer'
require_relative 'jsonapi/errors'

module Keygen
  module JSONAPI
    def self.render(...) = Renderer.new.render(...)
  end
end
