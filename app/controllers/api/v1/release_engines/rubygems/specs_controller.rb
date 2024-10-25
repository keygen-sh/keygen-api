# frozen_string_literal: true

module Api::V1::ReleaseEngines
  class Rubygems::SpecsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token
    before_action :set_artifact

    def quick
      authorize! artifact,
        to: :show?

      # rubygems expects a marshalled and zlib compressed gemspec
      gemspec    = artifact.specification.as_gemspec
      serialized = Marshal.dump(gemspec)
      compressed = Zlib::Deflate.deflate(
        serialized,
      )

      # for etag support
      return unless
        stale?(compressed, cache_control: { max_age: 1.day, private: true })

      send_data compressed, filename: "#{params[:gem]}.gemspec.rz"
    end

    private

    attr_reader :artifact

    def set_artifact
      scoped_artifacts = authorized_scope(current_account.release_artifacts.gems)
                           .joins(:specification) # must exist
                           .includes(
                             :specification,
                           )

      Current.resource = @artifact = FindByAliasService.call(
        scoped_artifacts,
        id: "#{params[:gem]}.gem",
        aliases: :filename,
      )
    end
  end
end
