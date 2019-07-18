# frozen_string_literal: true

class RecordMetricService < BaseService

  def initialize(metric:, account:, resource:)
    @metric   = metric
    @account  = account
    @resource = resource
  end

  def execute
    return if /^account/ =~ metric # We don't care about account events

    RecordMetricWorker.perform_async(
      metric,
      account.id,
      resource.class.name,
      resource.id
    )
  end

  private

  attr_reader :metric, :account, :resource
end
