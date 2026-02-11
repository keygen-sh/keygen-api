module Analytics
  class HeatmapNotFoundError < StandardError; end

  module Heatmap
    extend self

    Cell = Data.define(:date, :x, :y, :temperature, :count)

    def call(heatmap_id, account:, environment: nil, start_date: Date.current, end_date: 364.days.from_now.to_date)
      heatmap = case to_ident(heatmap_id)
                in :expirations then ExpirationsHeatmapQuery
                else nil
                end

      raise HeatmapNotFoundError, "invalid heatmap identifier: #{heatmap_id.inspect}" unless
        heatmap.present?

      heatmap.call(account:, environment:, start_date:, end_date:)
    end

    private

    def to_ident(id) = id.to_s.underscore.to_sym
  end
end
