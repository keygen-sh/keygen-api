module Api::V1
  class ApiController < ApplicationController
    include ActionController::Serialization

    private

    def set_current_account
      @current_account = Account.find_by_subdomain! request.subdomains.first
    end
  end
end
