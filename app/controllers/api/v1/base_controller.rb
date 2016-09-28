module Api::V1
  class BaseController < ApplicationController
    include ActionController::Serialization
    include TokenAuthentication
    include SubdomainScope
  end
end
