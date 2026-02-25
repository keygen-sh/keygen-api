# frozen_string_literal: true

class ClickhouseRecord < ActiveRecord::Base
  self.abstract_class = true

  connects_to database: { writing: :clickhouse, reading: :clickhouse }
end
