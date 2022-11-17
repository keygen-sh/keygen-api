# frozen_string_literal: true

module TypedParameters
  class Parser
    ##
    # parse reduces the input to an output, validated against the parameter schema.
    def parse(input, params:, path: nil)
      self.path = path

      catch :skip do
        input = validate!(input, params:)
        puts(validate!: input)
        input = coerce!(input, params:)
        puts(coerce!: input)

        reduce!(input, params:)
      end
    end

    private

    attr_accessor :path

    def reduce!(input, params:)
      case params.children
      when Hash
        raise InvalidParameterError.new(path:), "type mismatch (received #{Types.for(input).name} expected object)" unless
          input.is_a?(Hash)

        required_params = params.children.select { _2.required? }
        missing_keys    = required_params.keys.map(&:to_s) - input.keys.map(&:to_s)

        # FIXME(ezekg) This should raise for the first required param that is missing
        raise InvalidParameterError.new(path:), "required keys are missing: #{missing_keys.join(', ')}" if
          missing_keys.any?

        input.reduce({}) do |output, (key, value)|
          type  = Types.for(value)
          path  = [*self.path, key]

          if params.children.any?
            param = params.children.fetch(key) { nil }
            if param.nil?
              raise InvalidParameterError.new(path:), "key #{key} is not allowed" if params.strict?

              next output
            end

            # param.validations.each do |validation|
            #   validation.call(value:, param:, path:)
            # rescue InvalidParameterError
            #   raise if params.strict?
            #   next output
            # end

            # next output if
            #   !param.allow_blank? &&
            #   value.blank?

            # next output if
            #   param.allow_blank? &&
            #   param.optional? &&
            #   value.blank?

            # next output if
            #   param.optional? &&
            #   value.nil?

            output.merge(key => parse(value, params: param, path:))
          else
            raise InvalidParameterError.new(path:), "unpermitted type (expected object of scalar types)" unless
              type.scalar?

            output.merge(key => value)
          end
        end
      when Array
        raise InvalidParameterError.new(path:), "type mismatch (received #{Types.for(input).name} expected array)" unless
          input.is_a?(Array)

        required_params = params.children.select(&:required?)

        # FIXME(ezekg) This should raise for the first required item that is missing
        raise InvalidParameterError.new(path:), "required items are missing" if
          required_params.size > input.size

        input.each_with_index.reduce([]) do |output, (value, i)|
          type  = Types.for(value)
          path  = [*self.path, i]

          if params.children.any?
            param = params.children.fetch(i) { params.finalized? ? params.children.first : nil }
            if param.nil?
              raise InvalidParameterError.new(path:), "index #{i} is not allowed" if params.strict?

              next output
            end

            # param.validations.each do |validation|
            #   validation.call(value:, param:, path:)
            # rescue InvalidParameterError
            #   raise if params.strict?
            #   next output
            # end

            # next output if
            #   !param.allow_blank? &&
            #   value.blank?

            # next output if
            #   param.allow_blank? &&
            #   param.optional? &&
            #   value.blank?

            # next output if
            #   param.optional? &&
            #   value.nil?

            output.push(parse(value, params: param, path:))
          else
            raise InvalidParameterError.new(path:), "unpermitted type (expected array of scalar types)" unless
              type.scalar?

            output.push(value)
          end
        end
      else
        value = input
        type  = Types.for(value)

        raise InvalidParameterError.new(path:), "unpermitted type (expected scalar type)" unless
          type.scalar?

        value
      end
    end

    def validate!(value, params:)
      type = Types.for(value)

      puts(value:, t1: type, t2: params.type, mismatch?: params.type.mismatch?(type))

      # Validate the value against the parent's validations
      parent = params.parent

      parent&.validations&.each do |validation|
        validation.call(value:, params:, path:)
      rescue InvalidParameterError
        raise if params.strict?

        throw :skip
      end

      return value unless
        params.type.mismatch?(type)

      raise InvalidParameterError.new(path:), "type mismatch (received unknown expected #{params.type.name})" if
        type.nil?

      raise InvalidParameterError.new(path:), "type mismatch (received #{type.name} expected #{params.type.name})" unless
        params.coerce? && params.type.coercable?

      value
    end

    def coerce!(value, params:)
      type = Types.for(value)

      puts(value:,type:,params:params.type)

      return value unless
        params.type.mismatch?(type) &&
        params.type.coercable? &&
        params.coerce?

      params.type.coerce!(value)
    rescue FailedCoercionError
      raise InvalidParameterError.new(path:), 'could not be coerced'
    end
  end
end
