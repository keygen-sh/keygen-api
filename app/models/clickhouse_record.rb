# frozen_string_literal: true

class ClickhouseRecord < ActiveRecord::Base
  self.ignored_columns = %w[ver is_deleted] # internal columns for ReplacingMergeTree
  self.abstract_class  = true

  connects_to database: { writing: :clickhouse, reading: :clickhouse }
end
