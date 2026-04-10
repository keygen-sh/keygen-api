# frozen_string_literal: true

module Priv::Analytics
  class BaseController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :authenticate_with_token!
  end
end
