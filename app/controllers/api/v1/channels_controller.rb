# frozen_string_literal: true

module Api::V1
  class ChannelsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token
    before_action :set_channel, only: [:show]

    def index
      channels = apply_scopes(policy_scope(current_account.release_channels))
      authorize channels

      render jsonapi: channels
    end

    def show
      authorize channel

      render jsonapi: channel
    end

    private

    attr_reader :channel

    def set_channel
      scoped_channels = policy_scope(current_account.release_channels)

      @channel = scoped_channels.find params[:id]

      Current.resource = channel
    end
  end
end
