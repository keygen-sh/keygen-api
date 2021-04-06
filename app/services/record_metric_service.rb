# frozen_string_literal: true

class RecordMetricService < BaseService

  def initialize(metric:, account:, resource:)
    @metric   = metric
    @account  = account
    @resource = resource
  end

  def execute
    return if /^account/ =~ metric # We don't care about account events

    # FIXME(ezekg) Entitlement attach/detach events can be an array of resources. Need to
    #              handle this better, but this is a quick workaround in the interim.
    normalized_resource = Array.wrap(resource).first
    resource_name = normalized_resource&.class.name
    resource_id = normalized_resource&.id

    RecordMetricWorker.perform_async(
      metric,
      account.id,
      resource_name,
      resource_id
    )
  end

  private

  attr_reader :metric, :account, :resource
end
