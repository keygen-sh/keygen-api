# frozen_string_literal: true

require 'jsonapi/serializable/resource/conditional_fields'
require 'jsonapi/serializable/resource/key_format'

class BaseSerializer < JSONAPI::Serializable::Resource
  extend JSONAPI::Serializable::Resource::ConditionalFields
  extend JSONAPI::Serializable::Resource::KeyFormat

  key_format { it.to_s.camelize(:lower) }
  id         { @object.id }

  def self.ee(&) = Keygen.ee(&)
  def self.ce(&) = Keygen.ce(&)
end
