# frozen_string_literal: true

module TypedParameters
  class Schema
    ROOT_KEY = Class.new

    attr_reader :validations,
                :transforms,
                :parent,
                :children,
                :type,
                :key

    def initialize(
      strict: true,
      parent: nil,
      type: :hash,
      key: nil,
      optional: false,
      coerce: false,
      allow_blank: false,
      allow_nil: false,
      allow_non_scalars: false,
      nilify_blanks: false,
      inclusion: nil,
      exclusion: nil,
      format: nil,
      length: nil,
      transform: nil,
      validate: nil,
      &block
    )
      key ||= ROOT_KEY

      raise ArgumentError, 'key is required for child schema' if
        key == ROOT_KEY && parent.present?

      raise ArgumentError, 'root cannot be nil' if
        key == ROOT_KEY && allow_nil

      raise ArgumentError, 'inclusion must be a hash with :in key' unless
        inclusion.nil? || inclusion.is_a?(Hash) && inclusion.key?(:in)

      raise ArgumentError, 'exclusion must be a hash with :in key' unless
        exclusion.nil? || exclusion.is_a?(Hash) && exclusion.key?(:in)

      raise ArgumentError, 'format must be a hash with :with or :without keys (but not both)' unless
        format.nil? || format.is_a?(Hash) && (
          format.key?(:with) ^
          format.key?(:without)
        )

      raise ArgumentError, 'length must be a hash with :minimum, :maximum, :within, :in, or :is keys (but not multiple)' unless
        length.nil? || length.is_a?(Hash) && (
          length.key?(:minimum) ^
          length.key?(:maximum) ^
          length.key?(:within) ^
          length.key?(:in) ^
          length.key?(:is)
        )

      @type              = Types[type]
      @strict            = strict
      @parent            = parent
      @key               = key
      @optional          = optional
      @coerce            = coerce
      @allow_blank       = key == ROOT_KEY || allow_blank
      @allow_nil         = allow_nil
      @allow_non_scalars = allow_non_scalars
      @nilify_blanks     = nilify_blanks
      @inclusion         = inclusion
      @exclusion         = exclusion
      @format            = format
      @length            = length
      @transform         = transform
      @children          = nil

      # Validations
      @validations = []

      @validations << -> v { instance_exec(v, &INCLUSION_VALIDATOR) } if
        inclusion.present?

      @validations << -> v { instance_exec(v, &EXCLUSION_VALIDATOR) } if
        exclusion.present?

      @validations << -> v { instance_exec(v, &FORMAT_VALIDATOR) } if
        format.present?

      @validations << -> v { instance_exec(v, &LENGTH_VALIDATOR) } if
        length.present?

      @validations << validate if
        validate.present?

      # Transforms
      @transforms = []

      @transforms << NILIFY_BLANKS_TRANSFORMER if
        nilify_blanks

      @transforms << transform if
        transform.present?

      raise ArgumentError, "type #{type} is a not registered type" if
        @type.nil?

      if block_given?
        raise ArgumentError, "type #{@type} does not accept a block" if
          @type.present? && !@type.accepts_block?

        self.instance_exec &block
      end
    end

    ##
    # param defines a keyed parameter for a hash schema.
    def param(key, type:, **kwargs, &block)
      @children ||= {} if Types.hash?(self.type)

      raise NotImplementedError, "cannot define param for non-hash type (got #{self.type})" unless
        Types.hash?(children)

      raise ArgumentError, "key #{key} has already been defined" if
        children.key?(key)

      children[key] = Schema.new(**kwargs, key:, type:, strict:, parent: self, &block)
    end

    ##
    # params defines multiple like-parameters for a hash schema.
    def params(*keys, **kwargs, &) = keys.each { param(_1, **kwargs, &) }

    ##
    # item defines an indexed parameter for an array schema.
    def item(key = children.size, type:, **kwargs, &block)
      @children ||= [] if Types.array?(self.type)

      raise NotImplementedError, "cannot define item for non-array type (got #{self.type})" unless
        Types.array?(children)

      raise ArgumentError, "index #{key} has already been defined" if
        children[key].present? || boundless?

      children << Schema.new(**kwargs, key:, type:, strict:, parent: self, &block)
    end

    ##
    # items defines a set of like-parameters for an array schema.
    def items(**kwargs, &)
      item(0, **kwargs, &)

      boundless!
    end

    def required_keys
      case children
      when Array
        (0...children.filter { _1.required? }.size).to_a
      when Hash
        children.filter { _2.required? }.keys
      else
        []
      end
    end

    def root?              = key == ROOT_KEY
    def strict?            = !!strict
    def optional?          = !!@optional
    def required?          = !optional?
    def coerce?            = !!@coerce
    def allow_blank?       = !!@allow_blank
    def allow_nil?         = !!@allow_nil
    def allow_non_scalars? = !!@allow_non_scalars
    def nilify_blanks?     = !!@nilify_blanks
    def boundless?         = !!@boundless
    def indexed?           = !boundless?

    private

    INCLUSION_VALIDATOR = -> v {
      case @inclusion
      in in: in_value
        in_value.include?(v)
      end
    }.freeze
    private_constant :INCLUSION_VALIDATOR

    EXCLUSION_VALIDATOR = -> v {
      case @exclusion
      in in: in_value
        !in_value.include?(v)
      end
    }.freeze
    private_constant :EXCLUSION_VALIDATOR

    FORMAT_VALIDATOR = -> v {
      case @format
      in without:
        !without.match?(v)
      in with:
        with.match?(v)
      end
    }.freeze
    private_constant :FORMAT_VALIDATOR

    LENGTH_VALIDATOR = -> v {
      case @length
      in minimum:
        v.length >= minimum
      in maximum:
        v.length <= maximum
      in within:
        within.include?(v.length)
      in in: in_value
        in_value.include?(v.length)
      in is:
        v.length == is
      end
    }.freeze
    private_constant :LENGTH_VALIDATOR

    NILIFY_BLANKS_TRANSFORMER = -> k, v { [k, v.blank? ? nil : v] }.freeze
    private_constant :NILIFY_BLANKS_TRANSFORMER

    attr_reader :strict

    def boundless! = @boundless = true
  end
end
