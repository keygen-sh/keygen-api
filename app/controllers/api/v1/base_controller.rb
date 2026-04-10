# frozen_string_literal: true

module Api::V1
  class BaseController < ApplicationController
    include CurrentAccountConstraints
    include CurrentAccountScope
    include CurrentEnvironmentScope
    include Pagination

    private

    # mark controller action as requiring clickhouse to be enabled
    def self.use_clickhouse(**)
      before_action(**) do
        render_not_supported unless
          Keygen.database.clickhouse_available? && Keygen.database.clickhouse_enabled?
      end
    end
  end
end
