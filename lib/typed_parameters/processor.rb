# frozen_string_literal: true

module TypedParameters
  class Processor
    def initialize(schema:, controller: nil)
      @pipeline   = Pipeline.new
      @controller = controller
      @schema     = schema
    end

    def call(value)
      params = Parameterizer.new(schema:).call(value:)

      pipeline << Bouncer.new(controller:, schema:)
      pipeline << Coercer.new(schema:)
      pipeline << Validator.new(schema:)
      pipeline << Transformer.new(schema:)

      pipeline.call(params)
    end

    private

    attr_reader :controller,
                :pipeline,
                :schema
  end
end
