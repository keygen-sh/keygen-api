# frozen_string_literal: true

class ReleaseArchSerializer < BaseSerializer
  type 'arches'

  attribute :name
  attribute :key
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
  relationship :environment do
    linkage always: true do
      if @object.environment_id?
        { type: :environments, id: @object.environment_id }
      else
        nil
      end
    end
    link :related do
      @url_helpers.v1_account_arch_environment_path @object.account_id, @object
    end
  end

  link :related do
    @url_helpers.v1_account_arch_path @object.account_id, @object
  end
end
