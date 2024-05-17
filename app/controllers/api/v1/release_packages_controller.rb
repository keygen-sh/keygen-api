# frozen_string_literal: true

module Api::V1
  class ReleasePackagesController < Api::V1::BaseController
    has_scope(:product) { |c, s, v| s.for_product(v) }
    has_scope(:engine)  { |c, s, v| s.for_engine(v) }

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!, except: %i[index show]
    before_action :authenticate_with_token, only: %i[index show]
    before_action :set_package, only: %i[show update destroy]

    def index
      packages = apply_pagination(authorized_scope(apply_scopes(current_account.release_packages)).preload(:engine))
      authorize! packages

      render jsonapi: packages
    end

    def show
      authorize! package

      render jsonapi: package
    end

    typed_params {
      format :jsonapi

      param :data, type: :hash do
        param :type, type: :string, inclusion: { in: %w[package packages] }
        param :attributes, type: :hash do
          param :name, type: :string
          param :key, type: :string
          param :engine, type: :string, inclusion: { in: %w[pypi tauri] }, optional: true, allow_nil: true,
            transform: -> (_, key) {
              [:engine_attributes, { key: }]
            }
          param :metadata, type: :metadata, allow_blank: true, optional: true
        end
        param :relationships, type: :hash do
          param :product, type: :hash do
            param :data, type: :hash do
              param :type, type: :string, inclusion: { in: %w[product products] }
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
      package = current_account.release_packages.new(release_package_params)
      authorize! package

      if package.save
        BroadcastEventService.call(
          event: 'package.created',
          account: current_account,
          resource: package,
        )

        render jsonapi: package, status: :created, location: v1_account_release_package_url(package.account, package)
      else
        render_unprocessable_resource package
      end
    end

    typed_params {
      format :jsonapi

      param :data, type: :hash do
        param :type, type: :string, inclusion: { in: %w[package packages] }
        param :id, type: :string, optional: true, noop: true
        param :attributes, type: :hash do
          param :name, type: :string, optional: true
          param :key, type: :string, optional: true
          param :engine, type: :string, inclusion: { in: %w[pypi] }, optional: true, allow_nil: true,
            transform: -> (_, key) {
              [:engine_attributes, { key: }]
            }
          param :metadata, type: :metadata, allow_blank: true, optional: true
        end
      end
    }
    def update
      authorize! package

      if package.update(release_package_params)
        BroadcastEventService.call(
          event: 'package.updated',
          account: current_account,
          resource: package,
        )

        render jsonapi: package
      else
        render_unprocessable_resource package
      end
    end

    def destroy
      authorize! package

      BroadcastEventService.call(
        event: 'package.deleted',
        account: current_account,
        resource: package,
      )

      package.destroy
    end

    private

    attr_reader :package

    def set_package
      scoped_packages = authorized_scope(current_account.release_packages)

      @package = Current.resource = FindByAliasService.call(
        scoped_packages,
        id: params[:id],
        aliases: :key,
      )
    end
  end
end
