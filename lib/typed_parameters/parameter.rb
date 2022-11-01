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
                             {}
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

    ##
    # call reduces the input to an output according to the schema.
    def call(input, type: Types.for(input), path: nil)
      root = path

      # FIXME(ezekg) Extract this validation logic out into validators?
      if self.type != type
        raise InvalidParameterError.new(path:), "type mismatch (received unknown expected #{self.type.name})" if
          type.nil?

        raise InvalidParameterError.new(path:), "type mismatch (received #{type.name} expected #{self.type.name})" unless
          coerce? && self.type.coercable?

        begin
          input = self.type.coerce!(input)
        rescue CoerceFailedError
          raise InvalidParameterError.new(path:), 'could not be coerced'
        end
      end

      case children
      when Hash
        raise InvalidParameterError.new(path:), "type mismatch (received #{type.name} expected object)" unless
          type.type == :hash

        required_params = children.select { _2.required? }
        missing_keys    = required_params.keys - input.keys

        # FIXME(ezekg) This should raise for the first required param that is missing
        raise InvalidParameterError.new(path:), "required keys are missing: #{missing_keys.join(', ')}" if
          missing_keys.any?

        input.reduce({}) do |output, (key, value)|
          type  = Types.for(value)
          path  = [*root, key]

          if children.any?
            param = children.fetch(key) { nil }
            if param.nil?
              raise InvalidParameterError.new(path:), "key #{key} is not allowed" if strict?

              next output
            end

            next output if
              !param.allow_blank? &&
              value.blank?

            next output if
              param.optional? &&
              value.nil?

            output.merge(key => param.call(value, type:, path:))
          else
            raise InvalidParameterError.new(path:), "unpermitted type (expected object of scalar types)" unless
              type.scalar?

            output.merge(key => value)
          end
        end
      when Array
        raise InvalidParameterError.new(path:), "type mismatch (received #{type.name} expected array)" unless
          type.type == :array

        required_params = children.select(&:required?)

        # FIXME(ezekg) This should raise for the first required item that is missing
        raise InvalidParameterError.new(path:), "required items are missing" if
          required_params.size > input.size

        input.each_with_index.reduce([]) do |output, (value, i)|
          type  = Types.for(value)
          path  = [*root, i]
          if children.any?
            param = children.fetch(i) { finalized? ? children.first : nil }
            if param.nil?
              raise InvalidParameterError.new(path:), "index #{i} is not allowed" if strict?

              next output
            end

            next output if
              !allow_blank? &&
              value.blank?

            next output if
              optional? &&
              value.nil?

            output.push(param.call(value, type:, path:))
          else
            raise InvalidParameterError.new(path:), "unpermitted type (expected array of scalar types)" unless
              type.scalar?

            output.push(value)
          end
        end
      else
        value = input
        path  = [*root]

        raise InvalidParameterError.new(path:), "unpermitted type (expected scalar type)" unless
          type.scalar?

        value
      end
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
