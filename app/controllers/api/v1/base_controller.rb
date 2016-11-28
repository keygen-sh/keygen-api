module Api::V1
  class BaseController < ApplicationController
    include ActionController::Serialization
    include CurrentAccountScope
    include TokenAuthentication
    include SharedScopes
  end
end
