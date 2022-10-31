# frozen_string_literal: true

require_relative 'path'

module TypedParameters
  class Parameter
    attr_reader :type,
                :key

    def initialize(
      type:,
      key: nil,
      path: nil,
      optional: false,
      coerce: false,
      allow_blank: true,
      allow_nil: false,
      allow_non_scalars: false,
      inclusion: [],
      transform: nil,
      validate: nil
    )
      @type              = TypedParameters.types[type]
      @key               = key
      @path              = path || Path.new([*path&.keys, key].compact)
      @optional          = optional
      @coerce            = coerce
      @allow_blank       = allow_blank
      @allow_nil         = allow_nil
      @allow_non_scalars = allow_non_scalars
      @inclusion         = inclusion
      @transform         = transform
      @validate          = validate
    end

    def optional?          = !!@optional
    def coerce?            = !!@coerce
    def allow_blank?       = !!@allow_blank
    def allow_nil?         = !!@allow_nil
    def allow_non_scalars? = !!@allow_non_scalars
  end
end
