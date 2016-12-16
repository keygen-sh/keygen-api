module Api::V1
  class AccountsController < Api::V1::BaseController
    include TypedParameters::ControllerMethods

    has_scope :plan

    before_action :authenticate_with_token!, only: [:show, :update, :destroy]
    before_action :set_account, only: [:show, :update, :destroy]

    # GET /accounts
    def index
      @accounts = apply_scopes(Account).all
      authorize @accounts

      render jsonapi: @accounts
    end

    # GET /accounts/1
    def show
      render_not_found and return unless @account

      authorize @account

      render jsonapi: @account
    end

    # POST /accounts
    def create
      puts "PARAMS:", account_params.inspect
      # # puts "ATRS:", account_attributes.inspect
      # # puts "RELS:", account_relationships.inspect
      #
      # plan = Plan.find_by_hashid account_relationships.dig(:plan, :id)

      @account = Account.new account_params
      authorize @account

      if @account.save
        render jsonapi: @account, status: :created, location: v1_account_url(@account)
      else
        render_unprocessable_resource @account
      end
    end

    # PATCH/PUT /accounts/1
    def update
      render_not_found and return unless @account

      authorize @account

      if @account.update(account_attributes)
        render jsonapi: @account
      else
        render_unprocessable_resource @account
      end
    end

    # DELETE /accounts/1
    def destroy
      render_not_found and return unless @account

      authorize @account

      @account.destroy
    end

    private

    attr_reader :parameters

    def set_account
      @account = Account.friendly.find params[:id]
    end

    # def account_attributes
    #   parameters.fetch(:data, {}).fetch :attributes, {}
    # end
    #
    # def account_relationships
    #   parameters.fetch(:data, {}).fetch(:relationships, {}).each { |key, val|
    #     data = val.fetch :data, {}
    #
    #     case data
    #     when Array
    #       puts "ARRAY:", data
    #       data.map { |v| v.slice(:id).merge v.fetch(:attributes, {}) }
    #     when Hash
    #       puts "HASH:", data
    #       data.slice(:id).merge data.fetch(:attributes, {})
    #     end
    #   }
    # end

    # def parameters
    #   @parameters ||= TypedParameters.build self do
    #     options strict: true
    #
    #     on :create do
    #       param :data, type: :hash do
    #         param :type, type: :string, inclusion: %w[account accounts]
    #         param :attributes, type: :hash do
    #           param :name, type: :string
    #           param :slug, type: :string
    #         end
    #         param :relationships, type: :hash do
    #           param :plan, type: :hash do
    #             param :data, type: :hash do
    #               param :type, type: :string, inclusion: %w[plan plans]
    #               param :id, type: :string
    #             end
    #           end
    #           param :users_attributes, type: :hash, as: :admins do
    #             param :data, type: :array do
    #               items type: :hash do
    #                 param :type, type: :string, inclusion: %w[user users]
    #                 param :attributes, type: :hash do
    #                   param :name, type: :string
    #                   param :email, type: :string
    #                   param :password, type: :string
    #                 end
    #               end
    #             end
    #           end
    #         end
    #       end
    #     end
    #
    #     on :update do
    #       param :data, type: :hash do
    #         param :type, type: :string, inclusion: %w[account accounts]
    #         param :attributes, type: :hash do
    #           param :name, type: :string, optional: true
    #           param :slug, type: :string, optional: true
    #         end
    #       end
    #     end
    #   end
    # end

    typed_parameters transform: true do
      options strict: true

      on :create do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[account accounts]
          param :attributes, type: :hash do
            param :name, type: :string
            param :slug, type: :string
          end
          param :relationships, type: :hash do
            param :plan, type: :hash do
              param :data, type: :hash do
                param :type, type: :string, inclusion: %w[plan plans]
                param :id, type: :string
              end
            end
            param :admins, type: :hash do
              param :data, type: :array do
                items type: :hash do
                  param :type, type: :string, inclusion: %w[user users]
                  param :attributes, type: :hash do
                    param :name, type: :string
                    param :email, type: :string
                    param :password, type: :string
                  end
                end
              end
            end
          end
        end
      end

      on :update do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[account accounts]
          param :attributes, type: :hash do
            param :name, type: :string, optional: true
            param :slug, type: :string, optional: true
          end
        end
      end
    end
  end
end
