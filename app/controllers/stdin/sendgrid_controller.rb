# frozen_string_literal: true

module Stdin
  class SendgridController < ApplicationController
    def process
      skip_authorization

      render json: envelope
    end

    private

    def envelope
      JSON.parse(params.fetch(:envelope))
    end
  end
end
