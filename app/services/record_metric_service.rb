class RecordMetricService < BaseService

  def initialize(metric:, account:, data:)
    @metric   = metric
    @account  = account
    @data     = data
  end

  def execute
    return if /^account/ =~ metric # We don't care about account events

    MetricWorker.perform_async(
      metric,
      account.id,
      data.to_json
    )
  end

  private

  attr_reader :metric, :account, :data
end
