# frozen_string_literal: true

module Api::V1
  class TokensController < Api::V1::BaseController
    include ActionController::HttpAuthentication::Basic::ControllerMethods
    include ActionController::HttpAuthentication::Token::ControllerMethods

    has_scope(:bearer, type: :any) { |c, s, v| s.for_bearer(v) }

    before_action :scope_to_current_account!
    before_action :require_active_subscription!, only: %i[index regenerate regenerate_current]
    before_action :authenticate_with_password_or_token!, only: %i[generate]
    before_action :authenticate_with_token!, except: %i[generate]
    before_action :set_token, only: %i[show regenerate revoke]

    def index
      tokens = apply_pagination(authorized_scope(apply_scopes(current_account.tokens)).preload(:account, bearer: %i[role]))
      authorize! tokens

      render jsonapi: tokens
    end

    def show
      authorize! token

      render jsonapi: token
    end

    typed_params {
      format :jsonapi

      param :data, type: :hash, optional: true do
        param :type, type: :string, inclusion: { in: %w[token tokens] }
        param :attributes, type: :hash, optional: true do
          param :expiry, type: :time, allow_nil: true, optional: true, coerce: true
          param :name, type: :string, allow_nil: true, optional: true
          Keygen.ee do |license|
            next unless
              license.entitled?(:permissions)

            param :permissions, type: :array, optional: true, if: -> { current_account.ent? } do
              items type: :string
            end
          end
        end
        param :relationships, type: :hash, optional: true do
          param :bearer, type: :hash, polymorphic: true, optional: true do
            param :data, type: :hash do
              param :type, type: :string, inclusion: { in: %w[environment environments product products user users license licenses] }
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
      param :meta, type: :hash, optional: true do
        param :otp, type: :string
      end
    }
    def generate
      token = current_account.tokens.new(bearer: current_bearer, **token_params)
      authorize! token,
        context: { bearer: current_bearer },
        with: TokenPolicy

      # NOTE(ezekg) we only support session/cookie authn from portal origin
      session = if request.origin&.ends_with?(Keygen::Portal::HOST)
                  # TODO(ezekg) make default session expiry configurable
                  token.sessions.build(
                    expiry: token.expiry.presence || 1.week.from_now,
                    user_agent: request.user_agent,
                    ip: request.remote_ip,
                  )
                end

      if token.save
        set_session_id_cookie(session) if session in Session # lol nice

        BroadcastEventService.call(
          event: 'token.generated',
          account: current_account,
          resource: token,
        )

        render jsonapi: token, status: :created, location: v1_account_token_url(token.account, token)
      else
        render_unprocessable_resource token
      end
    end

    # FIXME(ezekg) deprecate this route
    def regenerate_current
      raise Keygen::Error::NotFoundError.new(model: Token.name) unless
        current_token.present?

      authorize! current_token,
        to: :regenerate?

      if session = current_token.regenerate!(session: current_session)
        set_session_id_cookie(session)
      end

      BroadcastEventService.call(
        event: 'token.regenerated',
        account: current_account,
        resource: current_token,
      )

      render jsonapi: current_token
    end

    def regenerate
      authorize! token

      # expire current session and generate a new one if we're revoking its token
      if session = token.regenerate!(session: current_session)
        set_session_id_cookie(session)
      end

      BroadcastEventService.call(
        event: 'token.regenerated',
        account: current_account,
        resource: token,
      )

      render jsonapi: token
    end

    def revoke
      authorize! token

      BroadcastEventService.call(
        event: 'token.revoked',
        account: current_account,
        resource: token,
      )

      # expire current session if we're revoking its token
      unless current_session.nil?
        reset_session_id_cookie if current_session.token == token
      end

      token.destroy
    end

    private

    attr_reader :token

    def set_token
      scoped_tokens = authorized_scope(current_account.tokens)

      @token = scoped_tokens.find(params[:id])

      Current.resource = token
    end
  end
end
