# frozen_string_literal: true

module Priv::Analytics
  class BaseController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :authenticate_with_token!

    private

    # mark controller action as requiring clickhouse to be enabled
    def self.use_clickhouse
      before_action do
        render_not_supported unless
          Keygen.database.clickhouse_available? && Keygen.database.clickhouse_enabled?
      end
    end
  end
end
