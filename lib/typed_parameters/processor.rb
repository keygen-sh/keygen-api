# frozen_string_literal: true

module TypedParameters
  class Processor
    def initialize(schema:)
      @pipeline = Pipeline.new
      @schema   = schema
    end

    def call(value)
      params = Parameterizer.new(schema:).call(value:)

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
