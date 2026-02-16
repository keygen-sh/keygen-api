# frozen_string_literal: true

module Analytics
  class HeatmapNotFoundError < StandardError; end

  module Heatmap
    def self.call(type, account:, environment: nil, start_date: Date.current, end_date: 364.days.from_now.to_date)
      klass = case type.to_s.underscore.to_sym
              in :expirations then Expirations
              else nil
              end

      raise HeatmapNotFoundError, "invalid heatmap type: #{type.inspect}" if klass.nil?

      klass.new(account:, environment:, start_date:, end_date:)
    end
  end
end
