module Api::V1
  class BaseController < Api::V1::ApplicationController
    include ActionController::Serialization
    include AccountScope
    include TokenAuth
  end
end
