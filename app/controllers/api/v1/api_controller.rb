module Api::V1
  class ApiController < ApplicationController
    include ActionController::Serialization

    # before_filter :set_current_account
    #
    # private
    #
    # def set_account
    #   @current_account = Account.find_by_subdomain! request.subdomains.first
    # end
  end
end
