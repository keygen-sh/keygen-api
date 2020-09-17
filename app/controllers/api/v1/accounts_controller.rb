# frozen_string_literal: true

module Api::V1
  class AccountsController < Api::V1::BaseController
    has_scope :plan

    before_action :scope_to_current_account!, only: [:show, :update, :destroy]
    before_action :authenticate_with_token!, only: [:show, :update, :destroy]
    before_action :set_account, only: [:show, :update, :destroy]

    # GET /accounts/1
    def show
      authorize @account

      render jsonapi: @account
    end

    # POST /accounts
    def create
      @account = Account.new account_params
      authorize @account

      # Use the admin's email domain as a fallback account name (maybe use Clearbit here?)
      admin, _ = account_params.fetch(:users_attributes, [])
      email = admin&.fetch(:email)

      # Extract the domain so that we can for the account's name and slug
      domain = email&.[](/[^@]+@(.+)/, 1)

      if @account.slug.nil?
        # Parameterize the domain, i.e. keygen.sh => keygen-sh
        slug = domain&.parameterize

        # Generate a random slug if the current one is nil, a public email
        # service, or if an account with that slug already exists.
        if slug.nil? || PUBLIC_EMAIL_SERVICES.include?(domain) || Account.exists?(slug: slug)
          trek_word = Faker::TvShows::StarTrek.location
          sw_word =  Faker::Movies::StarWars.planet
          color = Faker::Color.color_name

          slug = "acct-#{color}-#{sw_word}-#{trek_word}-#{SecureRandom.hex(4)}".downcase.parameterize
        end

        @account.slug = slug
      end

      if @account.name.nil?
        @account.name = domain
      end

      if @account.save
        render jsonapi: @account, status: :created, location: v1_account_url(@account)
      else
        render_unprocessable_resource @account
      end
    end

    # PATCH/PUT /accounts/1
    def update
      authorize @account

      if @account.update(account_params)
        CreateWebhookEventService.new(
          event: "account.updated",
          account: @account,
          resource: @account
        ).execute

        render jsonapi: @account
      else
        render_unprocessable_resource @account
      end
    end

    # DELETE /accounts/1
    def destroy
      authorize @account

      @account.destroy_async
    end

    private

    def set_account
      @account = @current_account
    end

    typed_parameters transform: true do
      options strict: true

      on :create do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[account accounts]
          param :attributes, type: :hash, optional: true do
            param :name, type: :string, optional: true
            param :slug, type: :string, optional: true
            param :protected, type: :boolean, optional: true
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
                    param :first_name, type: :string, optional: true
                    param :last_name, type: :string, optional: true
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
          param :id, type: :string, optional: true, transform: -> (k, v) { [] }
          param :attributes, type: :hash do
            param :name, type: :string, optional: true
            param :slug, type: :string, optional: true
            param :protected, type: :boolean, optional: true
          end
        end
      end
    end
  end
end
