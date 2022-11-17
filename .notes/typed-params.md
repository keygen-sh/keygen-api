# Typed Params

```rb
class UserController
  typed_params { param :foo }
  def create
    # ...
  end
end

module TypedParameters
  class ControllerMethods
    DEFERRED = Class.new

    cattr_accessor :typed_schemas

    def self.typed_params(on: DEFERRED, &)
      # TODO(ezekg) Deferred action via queue
      typed_schemas[on] = Schema.new(&)
    end

    def typed_params
      input     = params.to_unsafe_h.except(:controller, :format, :action)
      schema    = typed_schemas[action_name]
      processor = Processor.new(schema:)

      processor.call(input)
    end
  end

  class Schema
    def initialize(&) = instance_exec(&)
    def param(..., &) = nil
    def item(..., &) = nil
  end

  class Parameter
    def permitted? = valid?
    def valid?     = false
  end

  class Parameterizer
    def initialize(schema:) = @schema = schema

    def call(input)
      # Convert input into a tree of Parameter nodes
    end

    private

    attr_reader :schema
  end

  class Rule
    def initialize(schema:) = @schema = schema

    def call(...) = raise NotImplementedError

    private

    attr_reader :schema

    def depth_first_map(params)
      # TODO(ezekg) Map params outside-in with a DFS-like algo
    end
  end

  class Coercer < Rule
    def call(params)
      depth_first_map(params) do |param|
        # TODO(ezekg) Coerce params
      end
    end
  end

  class Validator < Rule
    def call(params)
      depth_first_map(params) do |param|
        # TODO(ezekg) Validate params
      end
    end
  end

  class Transformer < Rule
    def call(params)
      depth_first_map(params) do |param|
        # TODO(ezekg) Transform params
      end
    end
  end

  class Pipeline
    def initialize   = @steps = []
    def <<(step)     = @steps << step
    def call(params) = @steps.reduce(params) { |v, step| step.call(v) }
  end

  class Processor
    def initialize(schema:)
      @pipeline = Pipeline.new
      @schema   = schema
    end

    def call(input)
      params = Parameterizer.new(schema:).call(input)

      pipeline << Coercer.new(schema:)
      pipeline << Validator.new(schema:)
      pipeline << Transformer.new(schema:)

      pipeline.call(params)
    end

    private

    attr_reader :pipeline,
                :schema
  end
end
```
