# frozen_string_literal: true

module Analytics
  class Heatmap
    module Counters
      module Expirations
        def self.count(account:, environment:, start_date:, end_date:)
          account.licenses.unordered
                          .for_environment(environment)
                          .where.not(expiry: nil)
                          .where(expiry: start_date.beginning_of_day..end_date.end_of_day)
                          .group(Arel.sql('DATE(expiry)'))
                          .count
        end
      end
    end
  end
end
