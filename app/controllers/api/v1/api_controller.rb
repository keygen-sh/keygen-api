module Api::V1
  class ApiController < ApplicationController
    include ActionController::Serialization
    include SubdomainScope
    include AccessControl
  end
end
