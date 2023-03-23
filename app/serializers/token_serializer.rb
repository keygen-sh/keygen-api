# frozen_string_literal: true

class TokenSerializer < BaseSerializer
  type 'tokens'

  attribute :kind
  attribute :token, if: -> { @object.raw.present? && @context != :webhook } do
    @object.raw
  end
  attribute :expiry
  attribute :name
  attribute :max_activations, if: -> { @object.activation_token? }
  attribute :activations, if: -> { @object.activation_token? }
  attribute :max_deactivations, if: -> { @object.activation_token? }
  attribute :deactivations, if: -> { @object.activation_token? }
  attribute :permissions, if: -> { @account.ent? } do
    @object.permissions.actions
  end
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
        unless @object.environment_id.nil?
          @url_helpers.v1_account_environment_path @object.account_id, @object.environment_id
        end
      end
    end
  end

  relationship :bearer do
    linkage always: true
    link :related do
      @url_helpers.send "v1_account_#{@object.bearer_type.underscore}_path",
                        @object.account_id, @object.bearer_id
    end
  end

  link :self do
    @url_helpers.v1_account_token_path @object.account_id, @object
  end
end
