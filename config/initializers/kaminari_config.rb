# frozen_string_literal: true

Kaminari.configure do |config|
  config.page_method_name = :offset_paginate
  config.param_name       = :page
  config.default_per_page = 10
  config.max_per_page     = 100
end
