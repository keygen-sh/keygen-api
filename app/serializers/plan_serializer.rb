# frozen_string_literal: true

class PlanSerializer < BaseSerializer
  type 'plans'

  attribute :name
  attribute :price
  attribute :interval
  attribute :trial_duration
  attribute :request_log_retention_duration
  attribute :event_log_retention_duration
  attribute :max_reqs
  attribute :max_admins
  attribute :max_users
  attribute :max_policies
  attribute :max_licenses
  attribute :max_products
  attribute :max_storage
  attribute :max_transfer
  attribute :max_upload
  attribute :private, if: -> { @object.private? } do
    @object.private
  end
  attribute :created do
    @object.created_at
  end
  attribute :updated do
    @object.updated_at
  end

  link :self do
    @url_helpers.v1_plan_path @object
  end
end
