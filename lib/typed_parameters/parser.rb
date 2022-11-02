# frozen_string_literal: true

module TypedParameters
  class Parser
    ##
    # parse reduces the input to an output, validated against the parameter schema.
    def parse(input, params:, path: nil)
      self.path = path

      input = validate!(input, params:)
      input = coerce!(input, params:)

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

            next output if
              !param.allow_blank? &&
              value.blank?

            next output if
              param.allow_blank? &&
              param.optional? &&
              value.blank?

            next output if
              param.optional? &&
              value.nil?

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

            next output if
              !param.allow_blank? &&
              value.blank?

            next output if
              param.allow_blank? &&
              param.optional? &&
              value.blank?

            next output if
              param.optional? &&
              value.nil?

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

    private

    attr_accessor :path

    def validate!(input, params:)
      type = Types.for(input)

      return input unless
        params.type.mismatch?(type)

      raise InvalidParameterError.new(path:), "type mismatch (received unknown expected #{params.type.name})" if
        type.nil?

      raise InvalidParameterError.new(path:), "type mismatch (received #{type.name} expected #{params.type.name})" unless
        params.coerce? && params.type.coercable?

      input
    end

    def coerce!(input, params:)
      type = Types.for(input)

      return input unless
        params.type.mismatch?(type) &&
        params.type.coercable? &&
        params.coerce?

      params.type.coerce!(input)
    rescue CoerceFailedError
      raise InvalidParameterError.new(path:), 'could not be coerced'
    end
  end
end
