# frozen_string_literal: true

require_dependency Rails.root / 'lib' / 'keyset_pagination'

KeysetPagination.configure do |config|
  config.pagination_method_name = :keyset_paginate
  config.pagination_param_name  = :page

  config.default_page_size = 10
  config.max_page_size     = 100
end
