# frozen_string_literal: true

module TypedParameters
  class Pipeline
    def initialize   = @steps = []
    def <<(step)     = steps << step
    def call(params) = steps.reduce(params) { |v, step| step.call(v) }

    private

    attr_reader :steps
  end
end
