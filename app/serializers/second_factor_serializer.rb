# frozen_string_literal: true

class SecondFactorSerializer < BaseSerializer
  type 'second-factors'

  # Don't render secrets for second factors that are already enabled, or if
  # we're in a webhook context (so we don't leak user secrets).
  attribute :uri, unless: -> { @object.enabled? || @context == :webhook } do
    @object.uri
  end
  attribute :secret, unless: -> { @object.enabled? || @context == :webhook } do
    @object.secret
  end
  attribute :enabled
  attribute :created do
    @object.created_at
  end
  attribute :updated do
    @object.updated_at
  end

  relationship :account do
    linkage always: true do
      { type: :accounts, id: @object.account_id }
    end
    link :related do
      @url_helpers.v1_account_path @object.account_id
    end
  end

  ee do
    relationship :environment do
      linkage always: true do
        if @object.environment_id.present?
          { type: :environments, id: @object.environment_id }
        else
          nil
        end
      end
      link :related do
        if @object.environment_id.present?
          @url_helpers.v1_account_environment_path @object.account_id, @object.environment_id
        else
          nil
        end
      end
    end
  end

  relationship :user do
    linkage always: true do
      { type: :users, id: @object.user_id }
    end
    link :related do
      @url_helpers.v1_account_user_path @object.account_id, @object.user_id
    end
  end

  link :self do
    @url_helpers.v1_account_user_second_factor_path @object.account_id, @object.user_id, @object
  end
end
