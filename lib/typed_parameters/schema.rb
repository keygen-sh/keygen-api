# frozen_string_literal: true

require_relative 'parameter'

module TypedParameters
  class Schema
    attr_reader :parent,
                :children,
                :params,
                :param,
                :type

    def initialize(param: nil, strict: true, parent: nil, children: {}, params: {}, &block)
      @strict   = strict
      @parent   = parent
      @children = children
      @params   = params
      @param    = param
      @type     = param&.type

      if block_given?
        raise ArgumentError, "type #{type} does not accept a block" if
          type.present? && !type.accepts_block?

        self.instance_exec &block
      end
    end

    ##
    # param defines a keyed parameter for a hash schema.
    def param(key, **kwargs, &block)
      raise NotImplementedError, "cannot define param for non-hash type (got #{@type})" unless
        params.is_a?(Hash)

      param = Parameter.new(key:, **kwargs)

      raise ArgumentError, "#{param.type} is a not registered type (for #{param.path})" if
        param.type.nil?

      raise ArgumentError, "#{param.key} has already been defined" if
        params.key?(param.key)

      params[key] = param

      case param.type.to_sym
      when :hash
        children[key] = Schema.new(param:, strict:, parent: self, params: {}, &block)
      when :array
        children[key] = Schema.new(param:, strict:, parent: self, children: [], params: [], &block)
      else
        children[key] = Schema.new(param:, strict:, parent: self, children: nil, params: nil, &block)
      end
    end

    ##
    # item defines an indexed parameter for an array schema.
    def item(type:, **kwargs, &block)
      raise NotImplementedError, "cannot define item for non-array type (got #{@type})" unless
        params.is_a?(Array)

      param = Parameter.new(key: children.size, type:, **kwargs)

      raise ArgumentError, "#{type} is a not registered type (for #{param.path})" if
        param.type.nil?

      params << param

      case param.type.to_sym
      when :hash
        children << Schema.new(param:, strict:, parent: self, params: {}, &block)
      when :array
        children << Schema.new(param:, strict:, parent: self, children: [], params: [], &block)
      else
        children << Schema.new(param:, strict:, parent: self, children: nil, params: nil, &block)
      end
    end

    ##
    # items is an alias for item.
    def items(...) = item(...)

    ##
    # call reduces the input to an output according to the schema.
    def call(*args, **kwargs)
      case params
      when Hash
        kwargs.reduce({}) do |res, (key, value)|
          param = params[key]
          if param.nil?
            raise UnpermittedParameterError, "key #{key} is not allowed" if strict?

            next res
          end

          type = param.type

          if type.mismatch?(value)
            raise InvalidParameterError, "type mismatch (received #{Types.for(value).name} expected #{type.name})" unless
              param.coerce? && type.coercable?

            begin
              value = type.coerce!(value)
            rescue CoerceFailedError
              raise InvalidParameterError, 'could not be coerced'
            end
          end

          if children.key?(key)
            schema = children[key]

            case type.to_sym
            when :hash
              res.merge(key => schema.call(**value))
            when :array
              res.merge(key => schema.call(*value))
            else
              res.merge(key => schema.call(value))
            end
          else
            res.merge(key => value)
          end
        end
      when Array
        args.each_with_index.reduce([]) do |res, (value, i)|
          param = params[i] || params.first
          if param.nil?
            raise UnpermittedParameterError, "index #{i} is not allowed" if strict?

            next res
          end

          type = param.type

          if type.mismatch?(value)
            raise InvalidParameterError, "type mismatch (received #{Types.for(value).name} expected #{type.name})" unless
              param.coerce? && type.coercable?

            begin
              value = type.coerce!(value)
            rescue CoerceFailedError
              raise InvalidParameterError, 'could not be coerced'
            end
          end

          if schema = children[i] || children.first
            case type.to_sym
            when :hash
              res.push(schema.call(**value))
            when :array
              res.push(schema.call(*value))
            else
              res.push(schema.call(value))
            end
          else
            res.push(value)
          end
        end
      else
        args.sole
      end
    end

    def strict? = !!strict

    private

    attr_reader :strict
  end
end
