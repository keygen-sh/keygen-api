# frozen_string_literal: true

module Api::V1
  class ReleaseArtifactsController < Api::V1::BaseController
    has_scope(:channel) { |c, s, v| s.for_channel(v) }
    has_scope(:product) { |c, s, v| s.for_product(v) }
    has_scope(:release) { |c, s, v| s.for_release(v) }
    has_scope(:status) { |c, s, v| s.with_status(v) }
    has_scope(:package, allow_blank: true) { |c, s, v| s.for_package(v.presence) }
    has_scope(:engine, allow_blank: true) { |c, s, v| s.for_engine(v.presence) }
    has_scope(:filetype, allow_blank: true) { |c, s, v| s.for_filetype(v.presence) }
    has_scope(:platform, allow_blank: true) { |c, s, v| s.for_platform(v.presence) }
    has_scope(:arch, allow_blank: true) { |c, s, v| s.for_arch(v.presence) }

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!, except: %i[index show]
    before_action :authenticate_with_token, only: %i[index show]
    before_action :set_artifact, only: %i[show update destroy]

    def index
      # We're applying scopes after the policy scope because our policy scope
      # may include a UNION, and scopes/preloading need to be applied after
      # the UNION query has been performed. E.g. for LIMIT.
      artifacts = apply_pagination(authorized_scope(apply_scopes(current_account.release_artifacts)).preload(:platform, :arch, :filetype, release: %i[product entitlements constraints]))
      authorize! artifacts

      render jsonapi: artifacts
    end

    typed_query {
      param :ttl, type: :integer, coerce: true, allow_nil: true, optional: true, if: -> { current_bearer&.has_role?(:admin, :developer, :sales_agent, :support_agent, :product, :environment) }
    }
    def show
      authorize! artifact

      # Respond early if the artifact has not been uploaded (or is yanked) or
      # if the client prefers no download
      return render jsonapi: artifact if
        !artifact.downloadable? || prefers?('no-download')

      download = artifact.download!(
        path: params[:filename] || artifact.filename,
        ttl: release_artifact_query[:ttl],
      )

      BroadcastEventService.call(
        # NOTE(ezekg) The `release.downloaded` event is for backwards compat
        event: %w[artifact.downloaded release.downloaded],
        account: current_account,
        resource: artifact,
      )

      # Respond without a redirect if that's what the client prefers
      return render jsonapi: artifact, location: download.url if
        prefers?('no-redirect')

      render jsonapi: artifact, status: :see_other, location: download.url
    end

    typed_params {
      format :jsonapi

      param :data, type: :hash do
        param :type, type: :string, inclusion: { in: %w[artifact artifacts] }
        param :attributes, type: :hash do
          param :filename, type: :string
          param :filesize, type: :integer, allow_nil: true, optional: true
          param :filetype, type: :string, allow_blank: true, allow_nil: true, optional: true, transform: -> _, key {
            [:filetype_attributes, { key: }]
          }
          param :platform, type: :string, allow_blank: true, allow_nil: true, optional: true, transform: -> _, key {
            [:platform_attributes, { key: }]
          }
          param :arch, type: :string, allow_blank: true, allow_nil: true, optional: true, transform: -> _, key {
            [:arch_attributes, { key: }]
          }
          param :signature, type: :string, allow_blank: true, allow_nil: true, optional: true
          param :checksum, type: :string, allow_blank: true, allow_nil: true, optional: true
          param :metadata, type: :metadata, allow_blank: true, optional: true
        end
        param :relationships, type: :hash do
          param :release, type: :hash do
            param :data, type: :hash do
              param :type, type: :string, inclusion: { in: %w[release releases] }
              param :id, type: :uuid
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
      artifact = current_account.release_artifacts.new(release_artifact_params)
      authorize! artifact

      artifact.save!

      upload = artifact.upload!

      BroadcastEventService.call(
        event: 'artifact.created',
        account: current_account,
        resource: artifact,
      )

      # Respond without a redirect if that's what the client prefers
      render jsonapi: artifact, location: upload.url if
        prefers?('no-redirect')

      render jsonapi: artifact, status: :temporary_redirect, location: upload.url
    end

    typed_params {
      format :jsonapi

      param :data, type: :hash do
        param :type, type: :string, inclusion: { in: %w[artifact artifacts] }
        param :id, type: :string, optional: true, noop: true
        param :attributes, type: :hash do
          param :filesize, type: :integer, allow_nil: true, optional: true
          param :signature, type: :string, allow_blank: true, allow_nil: true, optional: true
          param :checksum, type: :string, allow_blank: true, allow_nil: true, optional: true
          param :metadata, type: :metadata, allow_blank: true, optional: true
        end
      end
    }
    def update
      authorize! artifact

      artifact.update!(release_artifact_params)

      BroadcastEventService.call(
        event: 'artifact.updated',
        account: current_account,
        resource: artifact,
      )

      render jsonapi: artifact
    end

    def destroy
      authorize! artifact

      artifact.yank!

      BroadcastEventService.call(
        event: 'artifact.deleted',
        account: current_account,
        resource: artifact,
      )
    end

    private

    attr_reader :artifact

    def set_artifact
      scoped_artifacts = authorized_scope(apply_scopes(current_account.release_artifacts))

      # NOTE(ezekg) Fetch the latest version of the artifact since we have no
      #             other qualifiers outside of a :filename alias.
      @artifact = FindByAliasService.call(
        scoped_artifacts.order_by_version,
        id: params[:id],
        aliases: :filename,
        reorder: false,
      )

      Current.resource = artifact
    end
  end
end
