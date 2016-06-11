module Api::V1
  class BaseController < ApplicationController
    include ActionController::Serialization
    include AccountScope
    include TokenAuth
  end
end
