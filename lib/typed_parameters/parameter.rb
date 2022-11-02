# frozen_string_literal: true

module TypedParameters
  class Parameter
    attr_reader :parent,
                :children,
                :type

    def initialize(
      strict: true,
      parent: nil,
      type: nil,
      key: nil,
      optional: false,
      coerce: false,
      allow_blank: true,
      allow_nil: false,
      allow_non_scalars: false,
      inclusion: [],
      transform: nil,
      validate: nil,
      &block
    )
      @strict            = strict
      @parent            = parent
      @key               = key
      @optional          = optional
      @coerce            = coerce
      @allow_blank       = allow_blank
      @allow_nil         = allow_nil
      @allow_non_scalars = allow_non_scalars
      @inclusion         = inclusion
      @transform         = transform
      @validate          = validate
      @type              = Types[type]
      @children          = case @type.to_sym
                           when :hash
                             {}.with_indifferent_access
                           when :array
                             []
                           else
                             nil
                           end

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
      raise NotImplementedError, "cannot define param for non-hash type (got #{@type})" unless
        children.is_a?(Hash)

      raise ArgumentError, "key #{key} has already been defined" if
        children.key?(key)

      case Types[type].to_sym
      when :hash
        children[key] = Parameter.new(**kwargs, key:, type:, strict:, parent: self, &block)
      when :array
        children[key] = Parameter.new(**kwargs, key:, type:, strict:, parent: self, &block)
      else
        children[key] = Parameter.new(**kwargs, key:, type:, strict:, parent: self, &block)
      end
    end

    ##
    # item defines an indexed parameter for an array schema.
    def item(key = children.size, type:, **kwargs, &block)
      raise NotImplementedError, "cannot define item for non-array type (got #{@type})" unless
        children.is_a?(Array)

      raise ArgumentError, "index #{key} has already been defined" if
        children[key].present? || finalized?

      case Types[type].to_sym
      when :hash
        children << Parameter.new(**kwargs, key:, type:, strict:, parent: self, &block)
      when :array
        children << Parameter.new(**kwargs, key:, type:, strict:, parent: self, &block)
      else
        children << Parameter.new(**kwargs, key:, type:, strict:, parent: self, &block)
      end
    end

    ##
    # items defines a set of like-parameters for an array schema.
    def items(**kwargs, &)
      item(0, **kwargs, &)

      finalize!
    end

    def strict?            = !!strict
    def optional?          = !!@optional
    def required?          = !optional?
    def coerce?            = !!@coerce
    def allow_blank?       = !!@allow_blank
    def allow_nil?         = !!@allow_nil
    def allow_non_scalars? = !!@allow_non_scalars
    def finalized?         = !!@finalized

    private

    attr_reader :strict

    def finalize! = @finalized = true
  end
end
