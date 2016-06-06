module Api::V1
  class BaseController < ApplicationController
    include ActionController::Serialization
    include SubdomainScope
    include AccessControl
  end
end
