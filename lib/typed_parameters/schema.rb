# frozen_string_literal: true

module TypedParameters
  class Schema
    attr_reader :validations,
                :transforms,
                :formatter,
                :parent,
                :children,
                :type,
                :key,
                :if,
                :unless

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
      noop: false,
      inclusion: nil,
      exclusion: nil,
      format: nil,
      length: nil,
      transform: nil,
      validate: nil,
      if: nil,
      unless: nil,
      &block
    )
      key ||= ROOT

      raise ArgumentError, 'key is required for child schema' if
        key == ROOT && parent.present?

      raise ArgumentError, 'root cannot be nil' if
        key == ROOT && allow_nil

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
      @allow_blank       = key == ROOT || allow_blank
      @allow_nil         = allow_nil
      @allow_non_scalars = allow_non_scalars
      @nilify_blanks     = nilify_blanks
      @noop              = noop
      @inclusion         = inclusion
      @exclusion         = exclusion
      @format            = format
      @length            = length
      @transform         = transform
      @children          = nil
      @if                = binding.local_variable_get(:if)
      @unless            = binding.local_variable_get(:unless)
      @formatter         = nil

      # Validations
      @validations = []

      @validations << Validations::Inclusion.new(inclusion) if
        inclusion.present?

      @validations << Validations::Exclusion.new(exclusion) if
        exclusion.present?

      @validations << Validations::Format.new(format) if
        format.present?

      @validations << Validations::Length.new(length) if
        length.present?

      @validations << validate if
        validate.present?

      # Transforms
      @transforms = []

      @transforms << Transforms::NilifyBlanks.new if
        nilify_blanks

      @transforms << Transforms::Noop.new if
        noop

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
    # format defines a final transform for the schema, transforming the
    # params from an input format to an output format, e.g. a JSONAPI
    # document to Rails' standard params format.
    def format(format) = @formatter = Formatters[format] || raise(ArgumentError, "invalid format: #{format.inspect}")

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
    def item(key = children&.size || 0, type:, **kwargs, &block)
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

    def path
      key = @key == ROOT ? nil : @key

      @path ||= Path.new(*parent&.path&.keys, *key)
    end

    def keys
      return [] if
        children.blank?

      case children
      when Array
        (0...children.size).to_a
      when Hash
        children.keys
      else
        []
      end
    end

    def root?              = key == ROOT
    def strict?            = !!strict
    def lenient?           = !strict?
    def optional?          = !!@optional
    def required?          = !optional?
    def coerce?            = !!@coerce
    def allow_blank?       = !!@allow_blank
    def allow_nil?         = !!@allow_nil
    def allow_non_scalars? = !!@allow_non_scalars
    def nilify_blanks?     = !!@nilify_blanks
    def boundless?         = !!@boundless
    def indexed?           = !boundless?
    def if?                = !@if.nil?
    def unless?            = !@unless.nil?
    def array?             = Types.array?(type)
    def hash?              = Types.hash?(type)
    def scalar?            = Types.scalar?(type)
    def formatter?         = !!@formatter

    def inspect
      "#<#{self.class.name} key=#{key.inspect} type=#{type.inspect} children=#{children.inspect}>"
    end

    private

    attr_reader :strict

    def boundless! = @boundless = true
  end
end
