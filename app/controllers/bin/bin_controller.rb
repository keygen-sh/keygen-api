# frozen_string_literal: true

module Bin
  class BinController < ApplicationController
    def show
      skip_authorization

      render status: :temporary_redirect, location: v1_account_artifact_path(account, artifact)
    end

    private

    def account
      params[:account_id]
    end

    def artifact
      params[:artifact_id]
    end
  end
end
