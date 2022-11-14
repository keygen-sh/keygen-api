# frozen_string_literal: true

module Api::V1
  class ReleasesController < Api::V1::BaseController
    has_scope(:yanked, type: :boolean, allow_blank: true) { |c, s, v| !!v ? s.yanked : s.unyanked }
    has_scope(:entitlements) { |c, s, v| s.within_constraints(v) }
    has_scope(:constraints) { |c, s, v| s.within_constraints(v) }
    has_scope(:channel) { |c, s, v| s.for_channel(v) }
    has_scope(:product) { |c, s, v| s.for_product(v) }
    has_scope(:status) { |c, s, v| s.with_status(v) }

    # FIXME(ezekg) Eventually remove these once we can confirm they're
    #              no longer being used
    has_scope(:filetype, if: -> c { c.current_api_version == '1.0' }) { |c, s, v| s.for_filetype(v) }
    has_scope(:platform, if: -> c { c.current_api_version == '1.0' }) { |c, s, v| s.for_platform(v) }
    has_scope(:arch,     if: -> c { c.current_api_version == '1.0' }) { |c, s, v| s.for_arch(v) }
    has_scope(:version,  if: -> c { c.current_api_version == '1.0' }) { |c, s, v| s.with_version(v) }

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!, except: %i[index show]
    before_action :authenticate_with_token, only: %i[index show]
    before_action :set_release, only: %i[show update destroy]

    def index
      # We're applying scopes and preloading after the policy scope because
      # our policy scope may include a UNION, and scopes/preloading need to
      # be applied after the UNION query has been performed.
      releases = apply_pagination(authorized_scope(apply_scopes(current_account.releases)).preload(:product, :channel, :constraints, :entitlements))
      authorize! releases

      render jsonapi: releases
    end

    def show
      authorize! release

      render jsonapi: release
    end

    def create
      release = current_account.releases.new(api_version: current_api_version, **release_params)
      authorize! release

      if release.save
        BroadcastEventService.call(
          event: 'release.created',
          account: current_account,
          resource: release,
        )

        render jsonapi: release, status: :created, location: v1_account_release_url(release.account_id, release)
      else
        render_unprocessable_resource release
      end
    end

    def update
      authorize! release

      if release.update(release_params)
        BroadcastEventService.call(
          event: 'release.updated',
          account: current_account,
          resource: release,
        )

        render jsonapi: release
      else
        render_unprocessable_resource release
      end
    end

    def destroy
      authorize! release

      BroadcastEventService.call(
        event: 'release.deleted',
        account: current_account,
        resource: release,
      )

      release.destroy_async
    end

    private

    attr_reader :release

    def set_release
      scoped_releases = authorized_scope(apply_scopes(current_account.releases))

      @release = FindByAliasService.call(
        scope: scoped_releases,
        identifier: params[:id],
        aliases: %i[version tag],
      )

      Current.resource = release
    end

    typed_parameters format: :jsonapi do
      options strict: true

      on :create do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[release releases]
          param :attributes, type: :hash do
            param :name, type: :string, optional: true
            param :description, type: :string, optional: true, allow_nil: true
            param :channel, type: :string, inclusion: %w[stable rc beta alpha dev], transform: -> (_, key) {
              [:channel_attributes, { key: }]
            }
            param :status, type: :string, inclusion: %w[DRAFT PUBLISHED], optional: true
            param :version, type: :string
            param :tag, type: :string, optional: true
            param :metadata, type: :hash, allow_non_scalars: true, optional: true
            if current_api_version == '1.0'
              param :filename, type: :string, optional: true
              param :filesize, type: :integer, optional: true
              param :filetype, type: :string, optional: true
              param :platform, type: :string, optional: true
              param :signature, type: :string, optional: true
              param :checksum, type: :string, optional: true
            end
          end
          param :relationships, type: :hash do
            param :product, type: :hash do
              param :data, type: :hash do
                param :type, type: :string, inclusion: %w[product products]
                param :id, type: :string
              end
            end
            param :constraints, type: :hash, optional: true do
              param :data, type: :array do
                items type: :hash do
                  param :type, type: :string, inclusion: %w[constraint constraints]
                  param :relationships, type: :hash do
                    param :entitlement, type: :hash do
                      param :data, type: :hash do
                        param :type, type: :string, inclusion: %w[entitlement entitlements]
                        param :id, type: :string
                      end
                    end
                  end
                end
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
            param :name, type: :string, optional: true, allow_nil: true
            param :description, type: :string, optional: true, allow_nil: true
            param :tag, type: :string, optional: true, allow_nil: true
            param :metadata, type: :hash, allow_non_scalars: true, optional: true
            if current_api_version == '1.0'
              param :filesize, type: :integer, optional: true, allow_nil: true
              param :signature, type: :string, optional: true, allow_nil: true
              param :checksum, type: :string, optional: true, allow_nil: true
            end
          end
        end
      end
    end
  end
end
