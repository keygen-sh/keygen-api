# frozen_string_literal: true

class GroupMemberSerializer < BaseSerializer
  type 'group-members'

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

  relationship :group do
    linkage always: true do
      { type: :groups, id: @object.group_id }
    end
    link :related do
      @url_helpers.v1_account_group_path @object.account_id, @object.group_id
    end
  end

  relationship :member do
    linkage always: true
    link :related do
      @url_helpers.send("v1_account_#{@object.member_type.underscore}_path", @object.account_id, @object.member_id)
    end
  end

  link :self do
    @url_helpers.v1_account_group_member_path @object.account_id, @object.group_id, @object.id
  end
end
