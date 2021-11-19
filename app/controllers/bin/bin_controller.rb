# frozen_string_literal: true

module Bin
  class BinController < ApplicationController
    def show
      skip_authorization

      render location: v1_account_artifact_url(account, artifact, protocol: 'https', host: 'api.keygen.sh'),
             status: :temporary_redirect
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
