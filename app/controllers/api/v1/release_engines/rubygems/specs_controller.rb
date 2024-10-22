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

      # rubygems expects a marshalled and gzipped gemspec
      gemspec = artifact.specification.as_gemspec
      dump    = Marshal.dump(gemspec)
      gz      = Zlib::Deflate.deflate(dump)

      send_data gz, filename: "#{params[:gem]}.gemspec.rz"
    end

    private

    attr_reader :artifact

    def set_artifact
      scoped_artifacts = authorized_scope(current_account.release_artifacts.gems)
                           .joins(:specification) # must exist
                           .eager_load(
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
