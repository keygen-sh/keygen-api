# frozen_string_literal: true

module Stdin
  class SendgridController < ApplicationController
    def receive_webhook
      skip_authorization

      render json: { from: mail.from, to: mail.to }
    end

    private

    def mail
      @mail ||= Mail.new(params.fetch(:email))
    end
  end
end
