# frozen_string_literal: true

module Api::V1::Machines::Relationships::V1x5
  class UsersController < ::Api::V1::Machines::Relationships::OwnersController
    def owner_params = user_params
  end
end
