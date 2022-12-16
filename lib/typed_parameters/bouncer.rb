# frozen_string_literal: true

require_relative 'mapper'

module TypedParameters
  class Bouncer < Mapper
    def call(params)
      depth_first_map(params) do |param|
        next unless
          param.schema.if? || param.schema.unless?

        cond = param.schema.if? ? param.schema.if : param.schema.unless
        res  = case cond
               in Proc => method
                 controller.instance_exec(&method)
               in Symbol => method
                 controller.send(method)
               else
                 raise InvalidMethodError, "invalid method: #{cond.inspect}"
               end

        next if
          param.schema.unless? && !res ||
          param.schema.if? && res

        if param.schema.strict?
          raise UnpermittedParameterError.new('unpermitted parameter', path: param.path, source: schema.source)
        else
          param.delete
        end
      end
    end
  end
end
