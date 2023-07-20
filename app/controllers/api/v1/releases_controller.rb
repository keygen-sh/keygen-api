# frozen_string_literal: true

module Api::V1
  class ReleasesController < Api::V1::BaseController
    has_scope(:yanked, type: :boolean, allow_blank: true) { |c, s, v| !!v ? s.yanked : s.unyanked }
    has_scope(:entitlements) { |c, s, v| s.within_constraints(v) }
    has_scope(:constraints) { |c, s, v| s.within_constraints(v) }
    has_scope(:channel) { |c, s, v| s.for_channel(v) }
    has_scope(:product) { |c, s, v| s.for_product(v) }
    has_scope(:package) { |c, s, v| s.for_package(v) }
    has_scope(:engine) { |c, s, v| s.for_engine(v) }
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

    typed_params {
      format :jsonapi

      param :data, type: :hash do
        param :type, type: :string, inclusion: { in: %w[release releases] }
        param :attributes, type: :hash do
          param :name, type: :string, allow_blank: true, allow_nil: true, optional: true
          param :description, type: :string, allow_nil: true, optional: true
          param :channel, type: :string, inclusion: { in: %w[stable rc beta alpha dev] }, transform: -> (_, key) {
            [:channel_attributes, { key: }]
          }
          param :status, type: :string, inclusion: { in: %w[DRAFT PUBLISHED] }, optional: true
          param :version, type: :string
          param :tag, type: :string, allow_blank: true, allow_nil: true, optional: true
          param :metadata, type: :metadata, allow_blank: true, optional: true
          with if: -> { current_api_version == '1.0' } do
            param :filename, type: :string, allow_blank: true, optional: true
            param :filesize, type: :integer, allow_nil: true, optional: true
            param :filetype, type: :string, allow_blank: true, optional: true
            param :platform, type: :string, allow_blank: true, optional: true
            param :signature, type: :string, allow_blank: true, optional: true
            param :checksum, type: :string, allow_blank: true, optional: true
          end
        end
        param :relationships, type: :hash do
          param :product, type: :hash do
            param :data, type: :hash do
              param :type, type: :string, inclusion: { in: %w[product products] }
              param :id, type: :uuid
            end
          end
          param :package, type: :hash, optional: true do
            param :data, type: :hash do
              param :type, type: :string, inclusion: { in: %w[package packages] }
              param :id, type: :uuid
            end
          end
          param :constraints, type: :hash, optional: true do
            param :data, type: :array do
              items type: :hash do
                param :type, type: :string, inclusion: { in: %w[constraint constraints] }
                param :relationships, type: :hash do
                  param :entitlement, type: :hash do
                    param :data, type: :hash do
                      param :type, type: :string, inclusion: { in: %w[entitlement entitlements] }
                      param :id, type: :uuid
                    end
                  end
                end
              end
            end
          end

          Keygen.ee do |license|
            next unless
              license.entitled?(:environments)

            param :environment, type: :hash, optional: true do
              param :data, type: :hash, allow_nil: true do
                param :type, type: :string, inclusion: { in: %w[environment environments] }
                param :id, type: :uuid
              end
            end
          end
        end
      end
    }
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

    typed_params {
      format :jsonapi

      param :data, type: :hash do
        param :type, type: :string, inclusion: { in: %w[release releases] }
        param :id, type: :uuid, optional: true, noop: true
        param :attributes, type: :hash do
          param :name, type: :string, allow_blank: true, allow_nil: true, optional: true
          param :description, type: :string, allow_blank: true, allow_nil: true, optional: true
          param :tag, type: :string, allow_blank: true, allow_nil: true, optional: true
          param :metadata, type: :metadata, allow_blank: true, optional: true
          with if: -> { current_api_version == '1.0' } do
            param :filesize, type: :integer, allow_nil: true, optional: true
            param :signature, type: :string, allow_blank: true, allow_nil: true, optional: true
            param :checksum, type: :string, allow_blank: true, allow_nil: true, optional: true
          end
        end
      end
    }
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

      release.destroy
    end

    private

    attr_reader :release

    def set_release
      scoped_releases = authorized_scope(apply_scopes(current_account.releases))

      @release = FindByAliasService.call(
        scoped_releases,
        id: params[:id],
        aliases: %i[version tag],
      )

      Current.resource = release
    end
  end
end
