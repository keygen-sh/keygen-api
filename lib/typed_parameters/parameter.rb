# frozen_string_literal: true

require_relative 'path'

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
      path: nil,
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
      @path              = path || Path.new([*path&.keys, key].compact)
      @optional          = optional
      @coerce            = coerce
      @allow_blank       = allow_blank
      @allow_nil         = allow_nil
      @allow_non_scalars = allow_non_scalars
      @inclusion         = inclusion
      @transform         = transform
      @validate          = validate
      @type              = Types[type]

      raise ArgumentError, "type #{type} is a not registered type (for #{path})" if
        @type.nil?

      @children = case @type.to_sym
                  when :hash
                    {}
                  when :array
                    []
                  else
                    nil
                  end

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
    def call(*args, **kwargs)
      case children
      when Hash
        required_params = children.select { _2.required? }
        missing_keys    = required_params.keys - kwargs.keys

        raise UnpermittedParameterError, "required keys are missing: #{missing_keys.join(', ')}" if
          missing_keys.any?

        kwargs.reduce({}) do |res, (key, value)|
          child = children[key]
          if child.nil?
            raise UnpermittedParameterError, "key #{key} is not allowed" if strict?

            next res
          end

          type = child.type

          if type.mismatch?(value)
            raise InvalidParameterError, "type mismatch (received #{Types.for(value).name} expected #{type.name})" unless
              child.coerce? && type.coercable?

            begin
              value = type.coerce!(value)
            rescue CoerceFailedError
              raise InvalidParameterError, 'could not be coerced'
            end
          end

          case type.to_sym
          when :hash
            res.merge(key => child.call(**value))
          when :array
            res.merge(key => child.call(*value))
          else
            res.merge(key => child.call(value))
          end
        end
      when Array
        required_params = children.select(&:required?)

        raise UnpermittedParameterError, "required items are missing" if
          required_params.size > args.size

        args.each_with_index.reduce([]) do |res, (value, i)|
          child = children.fetch(i) { finalized? ? children.first : nil }
          if child.nil?
            raise UnpermittedParameterError, "index #{i} is not allowed" if strict?

            next res
          end

          type = child.type

          if type.mismatch?(value)
            raise InvalidParameterError, "type mismatch (received #{Types.for(value).name} expected #{type.name})" unless
              child.coerce? && type.coercable?

            begin
              value = type.coerce!(value)
            rescue CoerceFailedError
              raise InvalidParameterError, 'could not be coerced'
            end
          end

          case type.to_sym
          when :hash
            res.push(child.call(**value))
          when :array
            res.push(child.call(*value))
          else
            res.push(child.call(value))
          end
        end
      else
        args.sole
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
