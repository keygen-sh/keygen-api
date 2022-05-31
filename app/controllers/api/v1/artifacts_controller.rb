# frozen_string_literal: true

module Api::V1
  class ArtifactsController < Api::V1::BaseController
    has_scope(:channel) { |c, s, v| s.for_channel(v) }
    has_scope(:product) { |c, s, v| s.for_product(v) }
    has_scope(:release) { |c, s, v| s.for_release(v) }
    has_scope(:status) { |c, s, v| s.with_status(v) }
    has_scope(:filetype) { |c, s, v| s.for_filetype(v) }
    has_scope(:platform) { |c, s, v| s.for_platform(v) }
    has_scope(:arch) { |c, s, v| s.for_arch(v) }

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!, except: %i[index show]
    before_action :authenticate_with_token, only: %i[index show]
    before_action :set_artifact, only: %i[show update destroy]

    def index
      # We're applying scopes after the policy scope because our policy scope
      # may include a UNION, and scopes/preloading need to be applied after
      # the UNION query has been performed. E.g. for LIMIT.
      artifacts = apply_pagination(apply_scopes(policy_scope(current_account.release_artifacts)).preload(:platform, :arch, :filetype))
      authorize artifacts

      render jsonapi: artifacts
    end

    def show
      authorize artifact

      if artifact.downloadable?
        download = artifact.download!(ttl: artifact_query[:ttl])

        BroadcastEventService.call(
          # NOTE(ezekg) The `release.downloaded` event is for backwards compat
          event: %w[artifact.downloaded release.downloaded],
          account: current_account,
          resource: artifact,
        )

        # Should we support `Prefer: no-redirect` for browser clients?
        render jsonapi: artifact, status: :see_other, location: download.url
      else
        render jsonapi: artifact
      end
    end

    def create
      artifact = current_account.release_artifacts.new(artifact_params)
      authorize artifact

      artifact.save!

      upload = artifact.upload!

      BroadcastEventService.call(
        event: 'artifact.created',
        account: current_account,
        resource: artifact,
      )

      # Should we support `Prefer: no-redirect` for browser clients?
      render jsonapi: artifact, status: :temporary_redirect, location: upload.url
    end

    def update
      authorize artifact

      artifact.update!(artifact_params)

      BroadcastEventService.call(
        event: 'artifact.updated',
        account: current_account,
        resource: artifact,
      )

      render jsonapi: artifact
    end

    def destroy
      authorize artifact

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
      scoped_artifacts = apply_scopes(policy_scope(current_account.release_artifacts))

      # NOTE(ezekg) Fetch the latest version of the artifact since we have no
      #             other qualifiers outside of a :filename alias.
      @artifact = FindByAliasService.call(
        scope: scoped_artifacts.order_by_version,
        identifier: params[:id],
        aliases: :filename,
        reorder: false,
      )

      Current.resource = artifact
    end

    typed_parameters format: :jsonapi do
      options strict: true

      on :create do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[artifact artifacts]
          param :attributes, type: :hash do
            param :filename, type: :string
            param :filesize, type: :integer, optional: true
            param :filetype, type: :string, optional: true, transform: -> (_, key) {
              [:filetype_attributes, { key: }]
            }
            param :platform, type: :string, optional: true, transform: -> (_, key) {
              [:platform_attributes, { key: }]
            }
            param :arch, type: :string, optional: true, transform: -> (_, key) {
              [:arch_attributes, { key: }]
            }
            param :signature, type: :string, optional: true
            param :checksum, type: :string, optional: true
            param :metadata, type: :hash, allow_non_scalars: true, optional: true
          end
          param :relationships, type: :hash do
            param :release, type: :hash do
              param :data, type: :hash do
                param :type, type: :string, inclusion: %w[release releases]
                param :id, type: :string
              end
            end
          end
        end
      end

      on :update do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[artifact artifacts]
          param :attributes, type: :hash do
            param :filesize, type: :integer, optional: true, allow_nil: true
            param :signature, type: :string, optional: true, allow_nil: true
            param :checksum, type: :string, optional: true, allow_nil: true
            param :metadata, type: :hash, allow_non_scalars: true, optional: true
          end
        end
      end
    end

    typed_query do
      on :show do
        if current_bearer&.has_role?(:admin, :developer, :sales_agent, :support_agent, :product)
          query :ttl, type: :integer, coerce: true, optional: true
        end
      end
    end
  end
end
