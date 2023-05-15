# frozen_string_literal: true

class GroupOwnerSerializer < BaseSerializer
  type 'group-owners'

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

  relationship :group do
    linkage always: true do
      { type: :groups, id: @object.group_id }
    end
    link :related do
      @url_helpers.v1_account_group_path @object.account_id, @object.group_id
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
    @url_helpers.v1_account_group_group_owner_path @object.account_id, @object.group_id, @object.id
  end
end
