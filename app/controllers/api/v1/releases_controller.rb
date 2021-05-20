# frozen_string_literal: true

module Api::V1
  class ReleasesController < Api::V1::BaseController
    has_scope(:yanked, type: :boolean, allow_blank: true) { |c, s, v| !!v ? s.yanked : s.unyanked }
    has_scope(:channel, default: 'stable') { |c, s, v| s.for_channel(v) }
    has_scope(:platform) { |c, s, v| s.for_platform(v) }
    has_scope(:filetype) { |c, s, v| s.for_filetype(v) }

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_release, only: [:show, :update, :destroy]

    def index
      releases = policy_scope apply_scopes(current_account.releases.preload(:platform, :filetype, :channel))
      authorize releases

      render jsonapi: releases
    end

    def show
      authorize release

      render jsonapi: release
    end

    def create
      release = current_account.releases.new release_params
      authorize release

      if release.save
        BroadcastEventService.call(
          event: 'release.created',
          account: current_account,
          resource: release
        )

        render jsonapi: release, status: :created, location: v1_account_release_url(release.account_id, release)
      else
        render_unprocessable_resource release
      end
    end

    def update
      authorize release

      if release.update(release_params)
        BroadcastEventService.call(
          event: 'release.updated',
          account: current_account,
          resource: release
        )

        render jsonapi: release
      else
        render_unprocessable_resource release
      end
    end

    def destroy
      authorize release

      BroadcastEventService.call(
        event: 'release.deleted',
        account: current_account,
        resource: release
      )

      release.destroy_async
    end

    private

    attr_reader :release

    def set_release
      @release = current_account.releases.find params[:id]

      Keygen::Store::Request.store[:current_resource] = release
    end

    typed_parameters transform: true do
      options strict: true

      on :create do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[release releases]
          param :attributes, type: :hash do
            param :name, type: :string, optional: true
            param :key, type: :string
            param :version, type: :string
            param :platform, type: :string, transform: -> (k, v) {
              [:platform_attributes, { key: v.downcase }]
            }
            param :filetype, type: :string, transform: -> (k, v) {
              [:filetype_attributes, { key: v.downcase }]
            }
            param :channel, type: :string, inclusion: %w[stable rc beta alpha dev], transform: -> (k, v) {
              [:channel_attributes, { key: v.downcase }]
            }
            param :filesize, type: :integer, optional: true
            param :metadata, type: :hash, optional: true
          end
          param :relationships, type: :hash do
            param :product, type: :hash do
              param :data, type: :hash do
                param :type, type: :string, inclusion: %w[product products]
                param :id, type: :string
              end
            end
          end
        end
      end

      on :update do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[release releases]
          param :id, type: :string, inclusion: [controller.params[:id]], optional: true, transform: -> (k, v) { [] }
          param :attributes, type: :hash do
            param :name, type: :string, optional: true
            param :filesize, type: :integer, optional: true
            param :metadata, type: :hash, optional: true
          end
        end
      end
    end
  end
end
