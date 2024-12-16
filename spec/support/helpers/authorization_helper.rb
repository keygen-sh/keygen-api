# frozen_string_literal: true

module AuthorizationHelper
  ##
  # Scenarios contains predefined scenarios to keep spec files clean and
  # easy to write (for security's sake) using pattern matching.
  module Scenarios
    ##
    # scenarios_for keeps track of scenarios by Rspec contexts.
    cattr_accessor :scenarios_for, default: {}

    ##
    # as_* matchers for defining the current :bearer.
    def as_admin(scenarios)
      case scenarios
      in []
        let(:account)     { create(:account, *account_traits) }
        let(:environment) { nil }
        let(:bearer)      { create(:admin, *bearer_traits, account:, permissions: bearer_permissions) }
      end
    end

    def as_environment(scenarios)
      case scenarios
      in []
        let(:account)     { create(:account, *account_traits) }
        let(:environment) { nil }
        let(:bearer)      { create(:environment, *bearer_traits, account:, permissions: bearer_permissions) }
      end
    end

    def as_product(scenarios)
      case scenarios
      in []
        let(:account)     { create(:account, *account_traits) }
        let(:environment) { nil }
        let(:bearer)      { create(:product, *bearer_traits, account:, permissions: bearer_permissions) }
      end
    end

    def as_license(scenarios)
      case scenarios
      in []
        let(:account)     { create(:account, *account_traits) }
        let(:environment) { nil }
        let(:bearer)      { create(:license, *license_traits, *bearer_traits, account:, permissions: bearer_permissions) }
      end
    end

    def as_user(scenarios)
      case scenarios
      in []
        let(:account)     { create(:account, *account_traits) }
        let(:environment) { nil }
        let(:bearer)      { create(:user, *bearer_traits, account:, permissions: bearer_permissions) }
      end
    end

    def as_group_owner(scenarios)
      case scenarios
      in [:as_user, :accessing_a_group, *]
        let!(:group_owner) { create(:group_owner, account:, group:, user: bearer) }
      end
    end

    def as_anonymous(scenarios)
      let(:account)     { create(:account, *account_traits) }
      let(:environment) { nil }
      let(:bearer)      { nil }
    end

    ##
    # accessing_* matchers for defining records and setting the current :record.
    # Typically, these will set the :record, as well as a named record, e.g.
    # a :license when accessing a license. The named record can be used in further
    # scenarios, such as with nested resources. E.g.:
    #
    #   %i[accessing_a_license accessing_its_entitlements]
    #
    def accessing_itself(scenarios)
      case scenarios
      in [:as_admin, *]
        let(:user)   { bearer }
        let(:record) { bearer }
      in [:as_environment, *]
        let(:environment) { bearer }
        let(:record)      { bearer }
      in [:as_product, *]
        let(:product) { bearer }
        let(:record)  { bearer }
      in [:as_license, *]
        let(:license) { bearer }
        let(:record)  { bearer }
      in [:as_user, *]
        let(:user)   { bearer }
        let(:record) { bearer }
      end
    end

    def accessing_accounts(scenarios)
      case scenarios
      in [:as_admin | :as_environment | :as_product | :as_license | :as_user | :as_anonymous, *]
        let(:accounts) { create_list(:account, 3) }
      end

      let(:record) { accounts }
    end

    def accessing_another_account(scenarios)
      case scenarios
      in [:as_admin | :as_environment | :as_product | :as_license | :as_user, *]
        let(:other_account) { create(:account) }
      end
    end

    def accessing_an_account(scenarios)
      case scenarios
      in [:as_admin | :as_environment | :as_product | :as_license | :as_user | :as_anonymous, *]
        let(:_account) { create(:account) }
      end

      let(:record) { _account }
    end

    def accessing_its_account(scenarios)
      case scenarios
      in [:as_admin | :as_environment | :as_product | :as_license | :as_user, *]
        # noop
      end

      let(:record) { account }
    end

    def accessing_billing(scenarios)
      case scenarios
      in [:as_admin | :as_environment | :as_product | :as_license | :as_user | :as_anonymous, *]
        let(:billing) { create(:billing, account:) }
      end

      let(:record) { billing }
    end

    def accessing_plan(scenarios)
      case scenarios
      in [:as_admin | :as_environment | :as_product | :as_license | :as_user | :as_anonymous, *]
        # noop
      end

      let(:record) { account.plan }
    end

    def accessing_analytics(scenarios)
      case scenarios
      in [:as_admin | :as_environment | :as_product | :as_license | :as_user | :as_anonymous, *]
        # noop
      end
    end

    def accessing_metrics(scenarios)
      case scenarios
      in [:as_admin | :as_environment | :as_product | :as_license | :as_user | :as_anonymous, *]
        let(:metrics) { create_list(:metric, 3, account:) }
      end

      let(:record) { metrics }
    end

    def accessing_a_metric(scenarios)
      case scenarios
      in [:as_admin | :as_environment | :as_product | :as_license | :as_user | :as_anonymous, *]
        let(:metric) { create(:metric, account:) }
      end

      let(:record) { metric }
    end

    def accessing_request_logs(scenarios)
      case scenarios
      in [:as_admin | :as_environment | :as_product | :as_license | :as_user | :as_anonymous, *]
        let(:request_logs) { create_list(:request_log, 3, account:) }
      end

      let(:record) { request_logs }
    end

    def accessing_a_request_log(scenarios)
      case scenarios
      in [:as_admin | :as_environment | :as_product | :as_license | :as_user | :as_anonymous, *]
        let(:request_log) { create(:request_log, account:) }
      end

      let(:record) { request_log }
    end

    def accessing_event_logs(scenarios)
      case scenarios
      in [:as_admin | :as_environment | :as_product | :as_license | :as_user | :as_anonymous, *]
        let(:event_logs) { create_list(:event_log, 3, account:) }
      end

      let(:record) { event_logs }
    end

    def accessing_an_event_log(scenarios)
      case scenarios
      in [:as_admin | :as_environment | :as_product | :as_license | :as_user | :as_anonymous, *]
        let(:event_log) { create(:event_log, account:) }
      end

      let(:record) { event_log }
    end

    def accessing_webhook_endpoints(scenarios)
      case scenarios
      in [:as_admin | :as_environment | :as_product | :as_license | :as_user | :as_anonymous, *]
        let(:webhook_endpoints) { create_list(:webhook_endpoint, 3, account:) }
      end

      let(:record) { webhook_endpoints }
    end

    def accessing_a_webhook_endpoint(scenarios)
      case scenarios
      in [:as_admin | :as_environment | :as_product | :as_license | :as_user | :as_anonymous, *]
        let(:webhook_endpoint) { create(:webhook_endpoint, account:) }
      end

      let(:record) { webhook_endpoint }
    end

    def accessing_webhook_events(scenarios)
      case scenarios
      in [:as_admin | :as_environment | :as_product | :as_license | :as_user | :as_anonymous, *]
        let(:webhook_events) { create_list(:webhook_event, 3, account:) }
      end

      let(:record) { webhook_events }
    end

    def accessing_a_webhook_event(scenarios)
      case scenarios
      in [:as_admin | :as_environment | :as_product | :as_license | :as_user | :as_anonymous, *]
        let(:webhook_event) { create(:webhook_event, account:) }
      end

      let(:record) { webhook_event }
    end

    def accessing_environments(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:environments) { create_list(:environment, 3, account: other_account) }
      else
        let(:environments) { create_list(:environment, 3, account:) }
      end

      let(:record) { environments }
    end

    def accessing_an_environment(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:_environment) { create(:environment, account: other_account) }
      else
        let(:_environment) { create(:environment, account:) }
      end

      let(:record) { _environment }
    end

    def accessing_a_product(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:product) { create(:product, *product_traits, account: other_account) }
      else
        let(:product) { create(:product, *product_traits, account:) }
      end

      let(:record) { product }
    end

    def accessing_its_product(scenarios)
      case scenarios
      in [*, :accessing_its_release | :accessing_a_release, *]
        let(:product) { release.product }
      in [*, :accessing_its_machine_component | :accessing_a_machine_component, *]
        let(:product) { machine_component.product }
      in [*, :accessing_its_machine_process | :accessing_a_machine_process, *]
        let(:product) { machine_process.product }
      in [*, :accessing_its_pooled_key | :accessing_a_pooled_key, *]
        let(:product) { pooled_key.product }
      in [*, :accessing_its_policy | :accessing_a_policy, *]
        let(:product) { _policy.product }
      in [*, :accessing_its_machine | :accessing_a_machine, *]
        let(:product) { machine.product }
      in [*, :accessing_its_license | :accessing_a_license, *]
        let(:product) { license.product }
      in [*, :accessing_its_user | :accessing_a_user, *]
        let(:product) {
          license = user.licenses.take || create(:license, *license_traits, account: user.account, owner: user)

          license.product
        }
      in [*, :accessing_its_owner, *]
        let(:product) {
          license = owner.licenses.take || create(:license, *license_traits, account: user.account, owner:)

          license.product
        }
      in [:as_license, *]
        let(:product) { bearer.product }
      in [:as_user, *]
        let(:product) { bearer.licenses.take.product }
      end

      let(:record) { product }
    end

    def accessing_products(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:products) { [create(:product, *product_traits, account: other_account)] }
      else
        let(:products) { [create(:product, *product_traits, account:)] }
      end

      let(:record) { products }
    end

    def accessing_its_products(scenarios)
      case scenarios
      in [*, :accessing_its_user | :accessing_a_user, *]
        let(:products) {
          licenses = user.licenses.presence || create_list(:license, 3, *license_traits, account: user.account, owner: user)

          licenses.collect(&:product)
        }
      in [*, :accessing_its_owner, *]
        let(:products) {
          licenses = owner.licenses.presence || create_list(:license, 3, *license_traits, account: user.account, owner:)

          licenses.collect(&:product)
        }
      in [:as_product, *]
        let(:products) { [bearer] }
      in [:as_license, *]
        let(:products) { [bearer.product] }
      in [:as_user, *]
        let(:products) { bearer.licenses.collect(&:product) }
      end

      let(:record) { products }
    end

    def accessing_policies(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:policies) { create_list(:policy, 3, *policy_traits, account: other_account) }
      else
        let(:policies) { create_list(:policy, 3, *policy_traits, account:) }
      end

      let(:record) { policies }
    end

    def accessing_a_policy(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:_policy) { create(:policy, *policy_traits, account: other_account) }
      else
        let(:_policy) { create(:policy, *policy_traits, account:) }
      end

      let(:record) { _policy }
    end

    def accessing_its_policies(scenarios)
      case scenarios
      in [*, :accessing_its_product | :accessing_a_product, *]
        let(:policies) { create_list(:policy, 3, *policy_traits, account: product.account, product:) }
      in [:as_product, *]
        let(:policies) { create_list(:policy, 3, *policy_traits, account: bearer.account, product: bearer) }
      in [:as_license, *]
        let(:policies) { [bearer.policy] }
      in [:as_user, *]
        let(:policies) { bearer.licenses.collect(&:policy) }
      end

      let(:record) { policies }
    end

    def accessing_its_policy(scenarios)
      case scenarios
      in [*, :accessing_its_product | :accessing_a_product, *]
        let(:_policy) { create(:policy, *policy_traits, account: product.account, product:) }
      in [*, :accessing_its_pooled_key | :accessing_a_pooled_key, *]
        let(:_policy) { pooled_key.policy }
      in [*, :accessing_its_license | :accessing_a_license, *]
        let(:_policy) { license.policy }
      in [:as_product, *]
        let(:_policy) { create(:policy, *policy_traits, account: bearer.account, product: bearer) }
      in [:as_license, *]
        let(:_policy) { bearer.policy }
      in [:as_user, *]
        let(:_policy) { bearer.licenses.take.policy }
      end

      let(:record) { _policy }
    end

    def accessing_tokens(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:tokens) { create_list(:token, 3, account: other_account) }
      else
        let(:tokens) {
          [
            create(:token, account:, bearer: create(:product, *product_traits, account:)),
            create(:token, account:, bearer: create(:license, *license_traits, account:)),
            create(:token, account:, bearer: create(:user, *user_traits, account:)),
          ]
        }
      end

      let(:record) { tokens }
    end

    def accessing_a_token(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:_token) { create(:token, account: other_account) }
      else
        let(:_token) { create(:token, account:) }
      end

      let(:record) { _token }
    end

    def accessing_its_tokens(scenarios)
      case scenarios
      in [*, :accessing_its_product | :accessing_a_product, *]
        let(:tokens)   { create_list(:token, 3, account: product.account, bearer: product) }
      in [*, :accessing_its_license | :accessing_a_license, *]
        let(:tokens)   { create_list(:token, 3, account: license.account, bearer: license) }
      in [*, :accessing_its_user | :accessing_a_user, *]
        let(:tokens)   { create_list(:token, 3, account: user.account, bearer: user) }
      in [*, :accessing_its_owner, *]
        let(:tokens)   { create_list(:token, 3, account: user.account, bearer: owner) }
      in [*, :accessing_itself, *]
        let(:tokens)   { create_list(:token, 3, account: bearer.account, bearer:) }
      in [:as_admin | :as_environment | :as_product | :as_license | :as_user, *]
        let(:tokens)   { create_list(:token, 3, account: bearer.account, bearer:) }
      end

      let(:record) { tokens }
    end

    def accessing_its_token(scenarios)
      case scenarios
      in [*, :accessing_its_product | :accessing_a_product, *]
        let(:_token) { create(:token, account: product.account, bearer: product) }
      in [*, :accessing_its_license | :accessing_a_license, *]
        let(:_token) { create(:token, account: license.account, bearer: license) }
      in [*, :accessing_its_user | :accessing_a_user, *]
        let(:_token) { create(:token, account: user.account, bearer: user) }
      in [*, :accessing_its_owner, *]
        let(:_token) { create(:token, account: user.account, bearer: owner) }
      in [*, :accessing_itself, *]
        let(:_token) { create(:token, account: bearer.account, bearer:) }
      in [:as_admin | :as_environment | :as_product | :as_license | :as_user, *]
        let(:_token) { create(:token, account: bearer.account, bearer:) }
      end

      let(:record) { _token }
    end

    def accessing_its_second_factors(scenarios)
      case scenarios
      in [*, :accessing_its_user | :accessing_a_user, *]
        let(:second_factors) { create_list(:second_factor, 1, account: user.account, user:) }
      in [*, :accessing_its_owner, *]
        let(:second_factors) { create_list(:second_factor, 1, account: user.account, user: owner) }
      in [:as_admin | :as_user, :accessing_itself, *]
        let(:second_factors) { create_list(:second_factor, 1, account:, user: bearer) }
      end

      let(:record) { second_factors }
    end

    def accessing_its_second_factor(scenarios)
      case scenarios
      in [*, :accessing_its_user | :accessing_a_user, *]
        let(:second_factor) { create(:second_factor, account: user.account, user:) }
      in [*, :accessing_its_owner, *]
        let(:second_factor) { create(:second_factor, account: user.account, user: owner) }
      in [:as_admin | :as_user, :accessing_itself, *]
        let(:second_factor) { create(:second_factor, account:, user: bearer) }
      end

      let(:record) { second_factor }
    end

    def accessing_admins(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:admins) { create_list(:admin, 3, *admin_traits, account: other_account) }
      else
        let(:admins) { create_list(:admin, 3, *admin_traits, account:) }
      end

      let(:record) { admins }
    end

    def accessing_an_admin(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:admin) { create(:admin, *admin_traits, account: other_account) }
      else
        let(:admin) { create(:admin, *admin_traits, account:) }
      end

      let(:record) { admin }
    end

    def accessing_users(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:users) { create_list(:user, 3, *user_traits, account: other_account) }
      else
        let(:users) { create_list(:user, 3, *user_traits, account:) }
      end

      let(:record) { users }
    end

    def accessing_a_user(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:user) { create(:user, *user_traits, account: other_account) }
      else
        let(:user) { create(:user, *user_traits, account:) }
      end

      let(:record) { user }
    end

    def accessing_its_users(scenarios)
      case scenarios
      in [*, :accessing_its_product | :accessing_a_product, *]
        let(:users) {
          policy = create(:policy, *policy_traits, account: product.account, product:)
          licenses = create_list(:license, 3, *license_traits, :with_owner, account: policy.account, policy:)

          licenses.collect(&:owner)
        }
      in [*, :accessing_its_license | :accessing_a_license, *]
        let(:users) {
          license.users
        }
      in [:as_license, :accessing_itself, *]
        let(:users) {
          license.users
        }
      in [:as_license, *]
        let(:users) {
          bearer.users
        }
      in [:as_product, :accessing_a_group, *]
        let(:users) {
          policy = create(:policy, *policy_traits, account:, product: bearer)
          users  = create_list(:user, 3, *user_traits, account:, group:)

          users.each { create(:license, *license_traits, account:, policy:, owner: _1) }

          users
        }
      in [*, :accessing_its_group | :accessing_a_group, *]
        let(:users) { create_list(:user, 3, *user_traits, account: group.account, group:) }
      in [:as_product, *]
        let(:users)     {
          policy = create(:policy, *policy_traits, account:, product: bearer)
          users  = create_list(:user, 3, *user_traits, account:)

          users.each { create(:license, *license_traits, account:, policy:, owner: _1) }

          users
        }
      end

      let(:record) { users }
    end

    def accessing_its_user(scenarios)
      case scenarios
      in [*, :accessing_its_product | :accessing_a_product, *]
        let(:user) {
          policy  = create(:policy, *policy_traits, account: product.account, product:)
          license = create(:license, *license_traits, :with_owner, account: policy.account, policy:)

          license.owner
        }
      in [*, :accessing_its_license | :accessing_a_license, *]
        let(:user) {
          license.users.take
        }
      in [:as_license, :accessing_itself, *]
        let(:user) {
          license.users.take
        }
      in [:as_license, *]
        let(:user) {
          bearer.users.take
        }
      in [:as_product, :accessing_a_group, *]
        let(:user) {
          policy = create(:policy, *policy_traits, account:, product: bearer)
          user   = create(:user, *user_traits, account:, group:)

          create(:license, *license_traits, account:, policy:, owner: user)

          user
        }
      in [*, :accessing_its_group | :accessing_a_group, *]
        let(:user) { create(:user, *user_traits, account: group.account, group:) }
      in [:as_product, *]
        let(:user) {
          policy = create(:policy, *policy_traits, account:, product: bearer)
          user   = create(:user, *user_traits, account:)

          create(:license, *license_traits, account:, policy:, owner: user)

          user
        }
      end

      let(:record) { user }
    end

    def accessing_its_teammates(scenarios)
      case scenarios
      in [:as_user, *]
        let(:users) { bearer.teammates }
      end

      let(:record) { users }
    end

    def accessing_its_teammate(scenarios)
      case scenarios
      in [:as_user, *]
        let(:user) { bearer.teammates.take }
      end

      let(:record) { user }
    end

    def accessing_groups(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:groups) { create_list(:group, 3, account: other_account) }
      else
        let(:groups) { create_list(:group, 3, account:) }
      end

      let(:record) { groups }
    end

    def accessing_a_group(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:group) { create(:group, account: other_account) }
      else
        let(:group) { create(:group, account:) }
      end

      let(:record) { group }
    end

    def accessing_its_groups(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:groups) { [create(:group, account: other_account)] }
      in [*, :accessing_its_license | :accessing_a_license, *]
        let(:groups) { [create(:group, account: license.account, licenses: [license])] }
      in [:as_license, *]
        let(:groups) { [create(:group, account:, licenses: [bearer])] }
      in [:as_user, *]
        let(:groups) { [create(:group, account:, users: [bearer]), *bearer.licenses.map(&:group)] }
      end

      let(:record) { groups }
    end

    def accessing_its_group(scenarios)
      case scenarios
      in [*, :accessing_its_license | :accessing_a_license, *]
        let(:group) { create(:group, account: license.account, licenses: [license]) }
      in [*, :accessing_its_machine | :accessing_a_machine, *]
        let(:group) { create(:group, account: machine.account, machines: [machine]) }
      in [*, :accessing_its_user | :accessing_a_user, *]
        let(:group) { create(:group, account: user.account, users: [user]) }
      in [*, :accessing_its_owner, *]
        let(:group) { create(:group, account: user.account, users: [owner]) }
      in [:as_license, *]
        let(:group) { create(:group, account:, licenses: [bearer]) }
      in [:as_user, *]
        let(:group) { create(:group, account:, users: [bearer]) }
      end

      let(:record) { group }
    end

    def accessing_entitlements(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:entitlements) { create_list(:entitlement, 3, account: other_account) }
      else
        let(:entitlements) { create_list(:entitlement, 3, account:) }
      end

      let(:record) { entitlements }
    end

    def accessing_an_entitlement(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:entitlement) { create(:entitlement, account: other_account) }
      else
        let(:entitlement) { create(:entitlement, account:) }
      end

      let(:record) { entitlement }
    end

    def accessing_its_entitlements(scenarios)
      case scenarios
      in [*, :accessing_its_release | :accessing_a_release, *]
        let(:entitlements) {
          constraints = create_list(:release_entitlement_constraint, 3, account: release.account, release:)

          constraints.map(&:entitlement)
        }
      in [*, :accessing_its_license | :accessing_a_license, *]
        let(:entitlements) { license.entitlements }
      in [*, :accessing_its_policy | :accessing_a_policy, *]
        let(:entitlements) { _policy.entitlements }
      in [:as_license, *]
        let(:entitlements) { bearer.entitlements }
      in [:as_user, *]
        let(:entitlements) { bearer.entitlements }
      end

      let(:record) { entitlements }
    end

    def accessing_its_entitlement(scenarios)
      case scenarios
      in [*, :accessing_its_release | :accessing_a_release, *]
        let(:entitlement) {
          constraint = create(:release_entitlement_constraint, account: release.account, release:)

          constraint.entitlement
        }
      in [*, :accessing_its_license | :accessing_a_license, *]
        let(:entitlement) { license.entitlements.take }
      in [*, :accessing_its_policy | :accessing_a_policy, *]
        let(:entitlement) { _policy.entitlements.take }
      in [:as_license, *]
        let(:entitlement) { bearer.entitlements.take }
      in [:as_user, *]
        let(:entitlement) { bearer.entitlements.take }
      end

      let(:record) { entitlement }
    end

    def accessing_machines(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:machines) { create_list(:machine, 3, *machine_traits, account: other_account) }
      else
        let(:machines) { create_list(:machine, 3, *machine_traits, account:) }
      end

      let(:record) { machines }
    end

    def accessing_a_machine(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:machine) { create(:machine, *machine_traits, account: other_account) }
      else
        let(:machine) { create(:machine, *machine_traits, account:) }
      end

      let(:record) { machine }
    end

    def accessing_its_machines(scenarios)
      case scenarios
      in [*, :accessing_its_product | :accessing_a_product, *]
        let(:machines) {
          policy = create(:policy, *policy_traits, account: product.account, product:)
          license = create(:license, *license_traits, account: policy.account, policy:)

          create_list(:machine, 3, *machine_traits, account: license.account, license:)
        }
      in [*, :accessing_its_license | :accessing_a_license, *]
        let(:machines) { create_list(:machine, 3, *machine_traits, account: license.account, license:) }
      in [*, :accessing_its_user | :accessing_a_user, *]
        let(:machines) {
          license = user.licenses.take || create(:license, *license_traits, account: user.account, owner: user)

          create_list(:machine, 3, *machine_traits, account: license.account, license:)
        }
      in [*, :accessing_its_owner, *]
        let(:machines) {
          license = owner.licenses.take || create(:license, *license_traits, account: user.account, owner:)

          create_list(:machine, 3, *machine_traits, account: license.account, license:)
        }
      in [*, :accessing_its_teammate, *]
        let(:machines) {
          user.machines.presence || begin
            license = create(:license, :with_users, *license_traits, account: user.account)

            create(:license_user, account: user.account, license:, user:)

            create_list(:machine, 3, *machine_traits, account: user.account, license:)
          end
        }
      in [:as_product, :accessing_a_group, *]
        let(:machines) {
          policy  = create(:policy, *policy_traits, account:, product: bearer)
          license = create(:license, *license_traits, account:, policy:)

          create_list(:machine, 3, *machine_traits, account:, license:, group:)
        }
      in [*, :accessing_its_group | :accessing_a_group, *]
        let(:machines) { create_list(:machine, 3, *machine_traits, account: group.account, group:) }
      in [:as_product, *]
        let(:machines) {
          policy  = create(:policy, *policy_traits, account:, product: bearer)
          license = create(:license, *license_traits, account:, policy:)

          create_list(:machine, 3, *machine_traits, account:, license:)
        }
      in [:as_license, *]
        let(:machines) { create_list(:machine, 3, *machine_traits, account:, license: bearer) }
      in [:as_user, *]
        let(:machines) { create_list(:machine, 3, *machine_traits, account:, license: bearer.licenses.take, owner: bearer) }
      end

      let(:record) { machines }
    end

    def accessing_its_machine(scenarios)
      case scenarios
      in [*, :accessing_its_product | :accessing_a_product, *]
        let(:machine) {
          policy = create(:policy, *policy_traits, account: product.account, product:)
          license = create(:license, *license_traits, account: policy.account, policy:)

          create(:machine, *machine_traits, account: license.account, license:)
        }
      in [*, :accessing_its_machine_component | :accessing_a_machine_component, *]
        let(:machine) { machine_component.machine }
      in [*, :accessing_its_machine_process | :accessing_a_machine_process, *]
        let(:machine) { machine_process.machine }
      in [*, :accessing_its_license | :accessing_a_license, *]
        let(:machine) { create(:machine, *machine_traits, account: license.account, license:) }
      in [*, :accessing_its_user | :accessing_a_user, *]
        let(:machine) {
          license = user.licenses.take || create(:license, *license_traits, account: user.account, owner: user)

          create(:machine, *machine_traits, account: license.account, license:)
        }
      in [*, :accessing_its_owner, *]
        let(:machine) {
          license = owner.licenses.take || create(:license, *license_traits, account: user.account, owner:)

          create(:machine, *machine_traits, account: license.account, license:)
        }
      in [*, :accessing_its_teammate, *]
        let(:machine) {
          user.machines.take || begin
            license = create(:license, :with_users, *license_traits, account: user.account)

            create(:license_user, account: user.account, license:, user:)

            create(:machine, *machine_traits, account: user.account, license:)
          end
        }
      in [:as_product, :accessing_a_group, *]
        let(:machine) {
          policy  = create(:policy, *policy_traits, account:, product: bearer)
          license = create(:license, *license_traits, account:, policy:)

          create(:machine, *machine_traits, account:, license:, group:)
        }
      in [*, :accessing_its_group | :accessing_a_group, *]
        let(:machine) { create(:machine, *machine_traits, account: group.account, group:) }
      in [:as_product, *]
        let(:machine) {
          policy  = create(:policy, *policy_traits, account:, product: bearer)
          license = create(:license, *license_traits, account:, policy:)

          create(:machine, *machine_traits, account:, license:)
        }
      in [:as_license, *]
        let(:machine) { create(:machine, *machine_traits, account:, license: bearer) }
      in [:as_user, *]
        let(:machine) {
          license = bearer.licenses.take || create(:license, *license_traits, account:, owner: bearer)

          create(:machine, *machine_traits, account:, license:, owner: bearer)
        }
      end

      let(:record) { machine }
    end

    def accessing_our_machines(scenarios)
      case scenarios
      in [:as_user, *]
        let(:machines) {
          license = create(:license, :with_users, *license_traits, account: bearer.account)

          create(:license_user, account: bearer.account, license:, user: bearer)

          create_list(:machine, 3, *machine_traits, account: bearer.account, license:)
        }
      end

      let(:record) { machines }
    end

    def accessing_our_machine(scenarios)
      case scenarios
      in [:as_user, *]
        let(:machine) {
          license = create(:license, :with_users, *license_traits, account: bearer.account)

          create(:license_user, account: bearer.account, license:, user: bearer)

          create(:machine, *machine_traits, account: bearer.account, license:)
        }
      end

      let(:record) { machine }
    end

    def accessing_machine_components(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:machine_components) { create_list(:component, 3, account: other_account) }
      else
        let(:machine_components) { create_list(:component, 3, account:) }
      end

      let(:record) { machine_components }
    end

    def accessing_a_machine_component(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:machine_component) { create(:component, account: other_account) }
      else
        let(:machine_component) { create(:component, account:) }
      end

      let(:record) { machine_component }
    end

    def accessing_its_machine_components(scenarios)
      case scenarios
      in [*, :accessing_its_machine | :accessing_a_machine, *]
        let(:machine_components) { create_list(:component, 3, account: machine.account, machine:) }
      in [:as_product, *]
        let(:_policy)            { create(:policy, *policy_traits, account:, product: bearer) }
        let(:_license)           { create(:license, *license_traits, account:, policy: _policy) }
        let(:_machine)           { create(:machine, *machine_traits, account:, license: _license) }
        let(:machine_components) { create_list(:component, 3, account:, machine: _machine) }
      in [:as_license, *]
        let(:_machine)           { create(:machine, *machine_traits, account:, license: bearer) }
        let(:machine_components) { create_list(:component, 3, account:, machine: _machine) }
      in [:as_user, *]
        let(:_machine)           { create(:machine, *machine_traits, account:, license: bearer.licenses.take, owner: bearer) }
        let(:machine_components) { create_list(:component, 3, account:, machine: _machine) }
      end

      let(:record) { machine_components }
    end

    def accessing_its_machine_component(scenarios)
      case scenarios
      in [*, :accessing_its_machine | :accessing_a_machine, *]
        let(:machine_component) { create(:component, account: machine.account, machine:) }
      in [:as_product, *]
        let(:_policy)           { create(:policy, *policy_traits, account:, product: bearer) }
        let(:_license)          { create(:license, *license_traits, account:, policy: _policy) }
        let(:_machine)          { create(:machine, *machine_traits, account:, license: _license) }
        let(:machine_component) { create(:component, account:, machine: _machine) }
      in [:as_license, *]
        let(:_machine)          { create(:machine, *machine_traits, account:, license: bearer) }
        let(:machine_component) { create(:component, account:, machine: _machine) }
      in [:as_user, *]
        let(:_machine)          { create(:machine, *machine_traits, account:, license: bearer.licenses.take, owner: bearer) }
        let(:machine_component) { create(:component, account:, machine: _machine) }
      end

      let(:record) { machine_component }
    end

    def accessing_our_machine_components(scenarios)
      case scenarios
      in [:as_user, *]
        let(:machine_components) {
          license = create(:license, :with_users, *license_traits, account: bearer.account)
          machine = create(:machine, *machine_traits, account: bearer.account, license:)

          create(:license_user, account: bearer.account, license:, user: bearer)

          create_list(:component, 3, account: bearer.account, machine:)
        }
      end

      let(:record) { machine_components }
    end

    def accessing_our_machine_component(scenarios)
      case scenarios
      in [:as_user, *]
        let(:machine_component) {
          license = create(:license, :with_users, *license_traits, account: bearer.account)
          machine = create(:machine, *machine_traits, account: bearer.account, license:)

          create(:license_user, account: bearer.account, license:, user: bearer)

          create(:component, account: bearer.account, machine:)
        }
      end

      let(:record) { machine_component }
    end

    def accessing_machine_processes(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:machine_processes) { create_list(:process, 3, account: other_account) }
      else
        let(:machine_processes) { create_list(:process, 3, account:) }
      end

      let(:record) { machine_processes }
    end

    def accessing_a_machine_process(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:machine_process) { create(:process, account: other_account) }
      else
        let(:machine_process) { create(:process, account:) }
      end

      let(:record) { machine_process }
    end

    def accessing_its_machine_processes(scenarios)
      case scenarios
      in [*, :accessing_its_machine | :accessing_a_machine, *]
        let(:machine_processes) { create_list(:process, 3, account: machine.account, machine:) }
      in [:as_product, *]
        let(:_policy)           { create(:policy, *policy_traits, account:, product: bearer) }
        let(:_license)          { create(:license, *license_traits, account:, policy: _policy) }
        let(:_machine)          { create(:machine, *machine_traits, account:, license: _license) }
        let(:machine_processes) { create_list(:process, 3, account:, machine: _machine) }
      in [:as_license, *]
        let(:_machine)          { create(:machine, *machine_traits, account:, license: bearer) }
        let(:machine_processes) { create_list(:process, 3, account:, machine: _machine) }
      in [:as_user, *]
        let(:_machine)          { create(:machine, *machine_traits, account:, license: bearer.licenses.take, owner: bearer) }
        let(:machine_processes) { create_list(:process, 3, account:, machine: _machine) }
      end

      let(:record) { machine_processes }
    end

    def accessing_its_machine_process(scenarios)
      case scenarios
      in [*, :accessing_its_machine | :accessing_a_machine, *]
        let(:machine_process) { create(:process, account: machine.account, machine:) }
      in [:as_product, *]
        let(:_policy)         { create(:policy, *policy_traits, account:, product: bearer) }
        let(:_license)        { create(:license, *license_traits, account:, policy: _policy) }
        let(:_machine)        { create(:machine, *machine_traits, account:, license: _license) }
        let(:machine_process) { create(:process, account:, machine: _machine) }
      in [:as_license, *]
        let(:_machine)        { create(:machine, *machine_traits, account:, license: bearer) }
        let(:machine_process) { create(:process, account:, machine: _machine) }
      in [:as_user, *]
        let(:_machine)        { create(:machine, *machine_traits, account:, license: bearer.licenses.take, owner: bearer) }
        let(:machine_process) { create(:process, account:, machine: _machine) }
      end

      let(:record) { machine_process }
    end

    def accessing_our_machine_processes(scenarios)
      case scenarios
      in [:as_user, *]
        let(:machine_processes) {
          license = create(:license, :with_users, *license_traits, account: bearer.account)
          machine = create(:machine, *machine_traits, account: bearer.account, license:)

          create(:license_user, account: bearer.account, license:, user: bearer)

          create_list(:process, 3, account: bearer.account, machine:)
        }
      end

      let(:record) { machine_processes }
    end

    def accessing_our_machine_process(scenarios)
      case scenarios
      in [:as_user, *]
        let(:machine_process) {
          license = create(:license, :with_users, *license_traits, account: bearer.account)
          machine = create(:machine, *machine_traits, account: bearer.account, license:)

          create(:license_user, account: bearer.account, license:, user: bearer)

          create(:process, account: bearer.account, machine:)
        }
      end

      let(:record) { machine_process }
    end

    def accessing_its_owners(scenarios)
      case scenarios
      in [*, :accessing_a_group, :as_group_owner, *]
        let(:owners) { create_list(:group_owner, 3, account: group.account, group:) << group_owner }
      in [*, :accessing_its_group | :accessing_a_group, *]
        let(:owners) { create_list(:group_owner, 3, account: group.account, group:) }
      end

      let(:record) { owners }
    end

    def accessing_its_owner(scenarios)
      case scenarios
      in [*, :accessing_a_group, :as_group_owner, *]
        let(:owner) { create(:group_owner, account: group.account, group:) }
      in [*, :accessing_its_group | :accessing_a_group, *]
        let(:owner) { create(:group_owner, account: group.account, group:) }
      in [*, :accessing_its_license | :accessing_a_license, *]
        let(:user)  { license.owner }
        let(:owner) { user }
      in [*, :accessing_its_machine_component | :accessing_a_machine_component, *]
        let(:user)  { machine_component.owner }
        let(:owner) { user }
      in [*, :accessing_its_machine_process | :accessing_a_machine_process, *]
        let(:user)  { machine_process.owner }
        let(:owner) { user }
      in [*, :accessing_its_machine | :accessing_a_machine, *]
        let(:user)  { machine.owner }
        let(:owner) { user }
      in [:as_license, *]
        let(:user)  { bearer.owner }
        let(:owner) { user }
      end

      let(:record) { owner }
    end

    def accessing_releases(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:releases) { create_list(:release, 3, *release_traits, account: other_account) }
      else
        let(:releases) { create_list(:release, 3, *release_traits, account:) }
      end

      let(:record) { releases }
    end

    def accessing_a_release(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:release) { create(:release, *release_traits, account: other_account) }
      else
        let(:release) { create(:release, *release_traits, account:) }
      end

      let(:record) { release }
    end

    def accessing_its_releases(scenarios)
      case scenarios
      in [*, :accessing_its_product | :accessing_a_product, *]
        let(:releases) { create_list(:release, 3, *release_traits, account: product.account, product:) }
      in [:as_product, *]
        let(:releases) { create_list(:release, 3, *release_traits, account:, product: bearer) }
      in [:as_license, *]
        let(:releases) { create_list(:release, 3, *release_traits, account:, product: bearer.product) }
      in [:as_user, *]
        let(:releases) { bearer.licenses.map { create(:release, *release_traits, account:, product: _1.product) } }
      end

      let(:record) { releases }
    end

    def accessing_its_release(scenarios)
      case scenarios
      in [*, :accessing_its_product | :accessing_a_product, *]
        let(:release) { create(:release, *release_traits, account: product.account, product:) }
      in [:as_product, *]
        let(:release) { create(:release, *release_traits, account:, product: bearer) }
      in [:as_license, *]
        let(:release) { create(:release, *release_traits, account:, product: bearer.product) }
      in [:as_user, *]
        let(:release) { create(:release, *release_traits, account:, product: bearer.licenses.take.product) }
      end

      let(:record) { release }
    end

    def accessing_artifacts(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:artifacts) { create_list(:artifact, 3, *artifact_traits, account: other_account) }
      else
        let(:artifacts) { create_list(:artifact, 3, *artifact_traits, account:) }
      end

      let(:record) { artifacts }
    end

    def accessing_an_artifact(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:artifact) { create(:artifact, *artifact_traits, account: other_account) }
      else
        let(:artifact) { create(:artifact, *artifact_traits, account:) }
      end

      let(:record) { artifact }
    end

    def accessing_its_artifacts(scenarios)
      case scenarios
      in [*, :accessing_its_release | :accessing_a_release, *]
        let(:artifacts) { create_list(:artifact, 3, *artifact_traits, account: release.account, release:) }
       in [*, :accessing_its_product | :accessing_a_product, *]
        let(:release)   { create(:release, *release_traits, account:, product:) }
        let(:artifacts) { create_list(:artifact, 3, *artifact_traits, account:, release:) }
      in [:as_product, :accessing_itself]
        let(:release)   { create(:release, *release_traits, account:, product: bearer) }
        let(:artifacts) { create_list(:artifact, 3, *artifact_traits, account:, release:) }
      in [:as_product, *]
        let(:releases)  { create_list(:release, 3, *release_traits, account:, product: bearer) }
        let(:artifacts) { releases.map { create(:artifact, *artifact_traits, account:, release: _1) } }
      in [:as_license, *]
        let(:releases)  { create_list(:release, 3, *release_traits, account:, product: bearer.product) }
        let(:artifacts) { releases.map { create(:artifact, *artifact_traits, account:, release: _1) } }
      in [:as_user, *]
        let(:releases)  { bearer.licenses.map { create(:release, *release_traits, account:, product: _1.product) } }
        let(:artifacts) { releases.map { create(:artifact, *artifact_traits, account:, release: _1) } }
      end

      let(:record) { artifacts }
    end

    def accessing_its_artifact(scenarios)
      case scenarios
      in [*, :accessing_its_release | :accessing_a_release, *]
        let(:artifact) { create(:artifact, *artifact_traits, account: release.account, release:) }
      in [*, :accessing_its_product | :accessing_a_product, *]
        let(:release)  { create(:release, *release_traits, account:, product:) }
        let(:artifact) { create(:artifact, *artifact_traits, account:, release:) }
      in [:as_product, :accessing_itself]
        let(:release)  { create(:release, *release_traits, account:, product: bearer) }
        let(:artifact) { create(:artifact, *artifact_traits, account:, release:) }
      in [:as_product, *]
        let(:release)  { create(:release, *release_traits, account:, product: bearer) }
        let(:artifact) { create(:artifact, *artifact_traits, account:, release:) }
      in [:as_license, *]
        let(:release)  { create(:release, *release_traits, account:, product: bearer.product) }
        let(:artifact) { create(:artifact, *artifact_traits, account:, release:) }
      in [:as_user, *]
        let(:release)  { create(:release, *release_traits, account:, product: bearer.licenses.take.product) }
        let(:artifact) { create(:artifact, *artifact_traits, account:, release:) }
      end

      let(:record) { artifact }
    end

    def accessing_manifests(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:manifests) { create_list(:manifest, 3, *manifest_traits, account: other_account) }
      else
        let(:manifests) { create_list(:manifest, 3, *manifest_traits, account:) }
      end

      let(:record) { manifests }
    end

    def accessing_a_manifest(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:manifest) { create(:manifest, *manifest_traits, account: other_account) }
      else
        let(:manifest) { create(:manifest, *manifest_traits, account:) }
      end

      let(:record) { manifest }
    end

    def accessing_its_manifests(scenarios)
      case scenarios
      in [*, :accessing_its_release | :accessing_a_release, *]
        let(:manifests) { create_list(:manifest, 3, *manifest_traits, account: release.account, release:) }
       in [*, :accessing_its_product | :accessing_a_product, *]
        let(:release)   { create(:release, *release_traits, account:, product:) }
        let(:artifact)  { create(:artifact, *artifact_traits, account:, release:) }
        let(:manifests) { create_list(:manifest, 3, *manifest_traits, account:, release:, artifact:) }
      in [:as_product, :accessing_itself]
        let(:release)   { create(:release, *release_traits, account:, product: bearer) }
        let(:artifact)  { create(:artifact, *artifact_traits, account:, release:) }
        let(:manifests) { create_list(:manifest, 3, *manifest_traits, account:, release:, artifact:) }
      in [:as_product, *]
        let(:releases)  { create_list(:release, 3, *release_traits, account:, product: bearer) }
        let(:artifacts) { releases.map { create(:artifact, *artifact_traits, account:, release: _1) } }
        let(:manifests) { releases.zip(artifacts).map { create(:manifest, *manifest_traits, account:, release: _1, artifact: _2) } }
      in [:as_license, *]
        let(:releases)  { create_list(:release, 3, *release_traits, account:, product: bearer.product) }
        let(:artifacts) { releases.map { create(:artifact, *artifact_traits, account:, release: _1) } }
        let(:manifests) { releases.zip(artifacts).map { create(:manifest, *manifest_traits, account:, release: _1, artifact: _2) } }
      in [:as_user, *]
        let(:releases)  { bearer.licenses.map { create(:release, *release_traits, account:, product: _1.product) } }
        let(:artifacts) { releases.map { create(:artifact, *artifact_traits, account:, release: _1) } }
        let(:manifests) { releases.zip(artifacts).map { create(:manifest, *manifest_traits, account:, release: _1, artifact: _2) } }
      end

      let(:record) { manifests }
    end

    def accessing_its_manifest(scenarios)
      case scenarios
      in [*, :accessing_its_release | :accessing_a_release, *]
        let(:artifact) { create(:artifact, *artifact_traits, account: release.account, release:) }
        let(:manifest) { create(:manifest, *manifest_traits, account: release.account, release:, artifact:) }
      in [*, :accessing_its_product | :accessing_a_product, *]
        let(:release)  { create(:release, *release_traits, account:, product:) }
        let(:artifact) { create(:artifact, *artifact_traits, account:, release:) }
        let(:manifest) { create(:manifest, *manifest_traits, account:, release:, artifact:) }
      in [:as_product, :accessing_itself]
        let(:release)  { create(:release, *release_traits, account:, product: bearer) }
        let(:artifact) { create(:artifact, *artifact_traits, account:, release:) }
        let(:manifest) { create(:manifest, *manifest_traits, account:, release:, artifact:) }
      in [:as_product, *]
        let(:release)  { create(:release, *release_traits, account:, product: bearer) }
        let(:artifact) { create(:artifact, *artifact_traits, account:, release:) }
        let(:manifest) { create(:manifest, *manifest_traits, account:, release:, artifact:) }
      in [:as_license, *]
        let(:release)  { create(:release, *release_traits, account:, product: bearer.product) }
        let(:artifact) { create(:artifact, *artifact_traits, account:, release:) }
        let(:manifest) { create(:manifest, *manifest_traits, account:, release:, artifact:) }
      in [:as_user, *]
        let(:release)  { create(:release, *release_traits, account:, product: bearer.licenses.take.product) }
        let(:artifact) { create(:artifact, *artifact_traits, account:, release:) }
        let(:manifest) { create(:manifest, *manifest_traits, account:, release:, artifact:) }
      end

      let(:record) { manifest }
    end

    def accessing_descriptors(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:descriptors) { create_list(:descriptor, 3, *descriptor_traits, account: other_account) }
      else
        let(:descriptors) { create_list(:descriptor, 3, *descriptor_traits, account:) }
      end

      let(:record) { descriptors }
    end

    def accessing_a_descriptor(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:descriptor) { create(:descriptor, *descriptor_traits, account: other_account) }
      else
        let(:descriptor) { create(:descriptor, *descriptor_traits, account:) }
      end

      let(:record) { descriptor }
    end

    def accessing_its_descriptors(scenarios)
      case scenarios
      in [*, :accessing_its_release | :accessing_a_release, *]
        let(:descriptors) { create_list(:descriptor, 3, *descriptor_traits, account: release.account, release:) }
       in [*, :accessing_its_product | :accessing_a_product, *]
        let(:release)     { create(:release, *release_traits, account:, product:) }
        let(:artifact)    { create(:artifact, *artifact_traits, account:, release:) }
        let(:descriptors) { create_list(:descriptor, 3, *descriptor_traits, account:, release:, artifact:) }
      in [:as_product, :accessing_itself]
        let(:release)     { create(:release, *release_traits, account:, product: bearer) }
        let(:artifact)    { create(:artifact, *artifact_traits, account:, release:) }
        let(:descriptors) { create_list(:descriptor, 3, *descriptor_traits, account:, release:, artifact:) }
      in [:as_product, *]
        let(:releases)    { create_list(:release, 3, *release_traits, account:, product: bearer) }
        let(:artifacts)   { releases.map { create(:artifact, *artifact_traits, account:, release: _1) } }
        let(:descriptors) { releases.zip(artifacts).map { create(:descriptor, *descriptor_traits, account:, release: _1, artifact: _2) } }
      in [:as_license, *]
        let(:releases)    { create_list(:release, 3, *release_traits, account:, product: bearer.product) }
        let(:artifacts)   { releases.map { create(:artifact, *artifact_traits, account:, release: _1) } }
        let(:descriptors) { releases.zip(artifacts).map { create(:descriptor, *descriptor_traits, account:, release: _1, artifact: _2) } }
      in [:as_user, *]
        let(:releases)    { bearer.licenses.map { create(:release, *release_traits, account:, product: _1.product) } }
        let(:artifacts)   { releases.map { create(:artifact, *artifact_traits, account:, release: _1) } }
        let(:descriptors) { releases.zip(artifacts).map { create(:descriptor, *descriptor_traits, account:, release: _1, artifact: _2) } }
      end

      let(:record) { descriptors }
    end

    def accessing_its_descriptor(scenarios)
      case scenarios
      in [*, :accessing_its_release | :accessing_a_release, *]
        let(:artifact)  { create(:artifact, *artifact_traits, account: release.account, release:) }
        let(:descriptor) { create(:descriptor, *descriptor_traits, account: release.account, release:, artifact:) }
      in [*, :accessing_its_product | :accessing_a_product, *]
        let(:release)    { create(:release, *release_traits, account:, product:) }
        let(:artifact)   { create(:artifact, *artifact_traits, account:, release:) }
        let(:descriptor) { create(:descriptor, *descriptor_traits, account:, release:, artifact:) }
      in [:as_product, :accessing_itself]
        let(:release)    { create(:release, *release_traits, account:, product: bearer) }
        let(:artifact)   { create(:artifact, *artifact_traits, account:, release:) }
        let(:descriptor) { create(:descriptor, *descriptor_traits, account:, release:, artifact:) }
      in [:as_product, *]
        let(:release)    { create(:release, *release_traits, account:, product: bearer) }
        let(:artifact)   { create(:artifact, *artifact_traits, account:, release:) }
        let(:descriptor) { create(:descriptor, *descriptor_traits, account:, release:, artifact:) }
      in [:as_license, *]
        let(:release)    { create(:release, *release_traits, account:, product: bearer.product) }
        let(:artifact)   { create(:artifact, *artifact_traits, account:, release:) }
        let(:descriptor) { create(:descriptor, *descriptor_traits, account:, release:, artifact:) }
      in [:as_user, *]
        let(:release)    { create(:release, *release_traits, account:, product: bearer.licenses.take.product) }
        let(:artifact)   { create(:artifact, *artifact_traits, account:, release:) }
        let(:descriptor) { create(:descriptor, *descriptor_traits, account:, release:, artifact:) }
      end

      let(:record) { descriptor }
    end

    def accessing_engines(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:engines) { create_list(:engine, 1, *engine_traits, account:) }
      else
        let(:engines) { create_list(:engine, 1, *engine_traits, account:) }
      end

      let(:record) { engines }
    end

    def accessing_engine(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:engine) { create(:engine, *engine_traits, account:) }
      else
        let(:engine) { create(:engine, *engine_traits, account:) }
      end

      let(:record) { engine }
    end

    def accessing_its_engines(scenarios)
      case scenarios
      in [*, :accessing_its_product | :accessing_a_product, *]
        let(:packages) { create_list(:package, 3, *package_traits, account:, product:) }
        let(:engines)  { packages.collect(&:engine) }
      in [:as_product, *]
        let(:packages) { create_list(:package, 3, *package_traits, product: bearer, account:) }
        let(:engines)  { packages.collect(&:engine) }
      in [:as_license, *]
        let(:packages) { create_list(:package, 3, *package_traits, product: bearer.product, account:) }
        let(:engines)  { packages.collect(&:engine) }
      in [:as_user, *]
        let(:packages) { create_list(:package, 3, *package_traits, product: bearer.licenses.take.product, account:) }
        let(:engines)  { packages.collect(&:engine) }
      end

      let(:record) { engines }
    end

    def accessing_its_engine(scenarios)
      case scenarios
      in [*, :accessing_its_release | :accessing_a_release, *]
        let(:package) { release.package }
        let(:engine)  { package.engine }
      in [*, :accessing_its_product | :accessing_a_product, *]
        let(:package) { create(:package, *package_traits, account:, product:) }
        let(:engine)  { package.engine }
      in [:as_product, *]
        let(:package) { create(:package, *package_traits, product: bearer, account:) }
        let(:engine)  { package.engine }
      in [:as_license, *]
        let(:package) { create(:package, *package_traits, product: bearer.product, account:) }
        let(:engine)  { package.engine }
      in [:as_user, *]
        let(:package) { create(:package, *package_traits, product: bearer.licenses.take.product, account:) }
        let(:engine)  { package.engine }
      end

      let(:record) { engine }
    end

    def accessing_packages(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:packages) { create_list(:package, 3, *package_traits, account: other_account) }
      else
        let(:packages) { create_list(:package, 3, *package_traits, account:) }
      end

      let(:record) { packages }
    end

    def accessing_package(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:package) { create(:package, *package_traits, account: other_account) }
      else
        let(:package) { create(:package, *package_traits, account:) }
      end

      let(:record) { package }
    end

    def accessing_its_packages(scenarios)
      case scenarios
      in [*, :accessing_its_product | :accessing_a_product, *]
        let(:packages) { create_list(:package, 3, *package_traits, account:, product:) }
      in [:as_product, *]
        let(:packages) { create_list(:package, 3, *package_traits, product: bearer, account:) }
      in [:as_license, *]
        let(:packages) { create_list(:package, 3, *package_traits, product: bearer.product, account:) }
      in [:as_user, *]
        let(:packages) { create_list(:package, 3, *package_traits, product: bearer.licenses.take.product, account:) }
      end

      let(:record) { packages }
    end

    def accessing_its_package(scenarios)
      case scenarios
      in [*, :accessing_its_release | :accessing_a_release, *]
        let(:package) { release.package }
      in [*, :accessing_its_product | :accessing_a_product, *]
        let(:package) { create(:package, *package_traits, account:, product:) }
      in [:as_product, *]
        let(:package) { create(:package, *package_traits, product: bearer, account:) }
      in [:as_license, *]
        let(:package) { create(:package, *package_traits, product: bearer.product, account:) }
      in [:as_user, *]
        let(:package) { create(:package, *package_traits, product: bearer.licenses.take.product, account:) }
      end

      let(:record) { package }
    end

    def accessing_its_constraints(scenarios)
      case scenarios
      in [*, :accessing_its_release | :accessing_a_release, *]
        let(:constraints) { create_list(:release_entitlement_constraint, 3, account: release.account, release:) }
      end

      let(:record) { constraints }
    end

    def accessing_its_constraint(scenarios)
      case scenarios
      in [*, :accessing_its_release | :accessing_a_release, *]
        let(:constraint) { create(:release_entitlement_constraint, account: release.account, release:) }
      end

      let(:record) { constraint }
    end

    def accessing_licenses(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:licenses) { create_list(:license, 3, *license_traits, account: other_account) }
      else
        let(:licenses) { create_list(:license, 3, *license_traits, account:) }
      end

      let(:record) { licenses }
    end

    def accessing_a_license(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:license) { create(:license, *license_traits, account: other_account) }
      else
        let(:license) { create(:license, *license_traits, account:) }
      end

      let(:record) { license }
    end

    def accessing_its_licenses(scenarios)
      case scenarios
      in [*, :accessing_its_product | :accessing_a_product, *]
        let(:licenses) {
          policy = create(:policy, *policy_traits, account: product.account, product:)

          create_list(:license, 3, *license_traits, account: policy.account, policy:)
        }
      in [*, :accessing_its_policy | :accessing_a_policy, *]
        let(:licenses) { create_list(:license, 3, *license_traits, account: _policy.account, policy: _policy) }
      in [*, :accessing_its_user | :accessing_a_user, *]
        let(:licenses) {
          user.licenses.presence || create_list(:license, 3, *license_traits, account: user.account, owner: user)
        }
      in [*, :accessing_its_owner, *]
        let(:licenses) {
          owner.licenses.presence || create_list(:license, 3, *license_traits, account: owner.account, owner:)
        }
      in [*, :accessing_its_teammate, *]
        let(:licenses) {
          user.licenses.presence || begin
            license = create(:license, :with_users, *license_traits, account: user.account)

            create(:license_user, account: user.account, license:, user:)

            user.licenses
          end
        }
      in [:as_product, :accessing_a_group, *]
        let(:licenses) {
          policy = create(:policy, *policy_traits, account:, product: bearer)

          create_list(:license, 3, *license_traits, account:, policy:, group:)
        }
      in [*, :accessing_its_group | :accessing_a_group, *]
        let(:licenses) { create_list(:license, 3, *license_traits, account: group.account, group:) }
      in [:as_product, *]
        let(:licenses) {
          policy = create(:policy, *policy_traits, account:, product: bearer)

          create_list(:license, 3, *license_traits, account:, policy:)
        }
      in [:as_user, *]
        let(:licenses) { bearer.licenses }
      end

      let(:record) { licenses }
    end

    def accessing_its_license(scenarios)
      case scenarios
      in [*, :accessing_its_product | :accessing_a_product, *]
        let(:license) {
          policy = create(:policy, *policy_traits, account: product.account, product:)

          create(:license, *license_traits, account: policy.account, policy:)
        }
      in [*, :accessing_its_machine_component | :accessing_a_machine_component, *]
        let(:license) { machine_component.license }
      in [*, :accessing_its_machine_process | :accessing_a_machine_process, *]
        let(:license) { machine_process.license }
      in [*, :accessing_its_policy | :accessing_a_policy, *]
        let(:license) { create(:license, *license_traits, account: _policy.account, policy: _policy) }
      in [*, :accessing_its_user | :accessing_a_user, *]
        let(:license) {
          user.licenses.take || create(:license, *license_traits, account: user.account, owner: user)
        }
      in [*, :accessing_its_owner, *]
        let(:license) {
          owner.licenses.take || create(:license, *license_traits, account: user.account, owner:)
        }
      in [*, :accessing_its_teammate, *]
        let(:license) {
          user.licenses.take || begin
            license = create(:license, :with_users, *license_traits, account: user.account)

            create(:license_user, account: user.account, license:, user:)

            license
          end
        }
      in [*, :accessing_its_machine | :accessing_a_machine, *]
        let(:license) { machine.license }
      in [:as_product, :accessing_a_group, *]
        let(:license) {
          policy = create(:policy, *policy_traits, account:, product: bearer)

          create(:license, *license_traits, account:, policy:, group:)
        }
      in [*, :accessing_its_group | :accessing_a_group, *]
        let(:license) { create(:license, *license_traits, account: group.account, group:) }
      in [:as_product, *]
        let(:license) {
          policy = create(:policy, *policy_traits, account:, product: bearer)

          create(:license, *license_traits, account:, policy:)
        }
      in [:as_user, *]
        let(:license) {
          bearer.licenses.take || create(:license, *license_traits, account: bearer.account, owner: bearer)
        }
      end

      let(:record) { license }
    end

    def accessing_its_license_file(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:license_file) { build(:license_file, account: other_account) }
      in [*, :accessing_its_license | :accessing_a_license, *]
        let(:license_file) {
          build(:license_file, account:, license:, environment:)
        }
      in [:as_license, :accessing_itself, *]
        let(:license_file) {
          build(:license_file, account:, license: bearer, environment:)
        }
      end

      let(:record) { license_file }
    end

    def accessing_its_machine_file(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:machine_file) { build(:machine_file, account: other_account) }
      in [*, :accessing_its_machine | :accessing_a_machine, *]
        let(:machine_file) {
          build(:machine_file, account:, machine:, license: machine.license, environment:)
        }
      end

      let(:record) { machine_file }
    end

    def accessing_a_pooled_key(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:pooled_key) { create(:key, account: other_account) }
      else
        let(:pooled_key) { create(:key, account:) }
      end

      let(:record) { pooled_key }
    end

    def accessing_its_pooled_keys(scenarios)
      case scenarios
      in [*, :accessing_its_policy | :accessing_a_policy, *]
        let(:pooled_keys) {
          _policy.update!(use_pool: true)

          create_list(:key, 3, account: _policy.account, policy: _policy)
        }
      end

      let(:record) { pooled_keys }
    end

    def accessing_its_pooled_key(scenarios)
      case scenarios
      in [*, :accessing_its_policy | :accessing_a_policy, *]
        let(:pooled_key) {
          _policy.update!(use_pool: true)

          create(:key, account: _policy.account, policy: _policy)
        }
      in [:as_product, *]
        let(:policy)     { create(:policy, *policy_traits, :pooled, account:, product: bearer) }
        let(:pooled_key) { create(:key, account:, policy:) }
      end

      let(:record) { pooled_key }
    end

    def accessing_its_pooled_key(scenarios)
      case scenarios
      in [*, :accessing_its_policy | :accessing_a_policy, *]
        let(:pooled_key) {
          _policy.update!(use_pool: true)

          create(:key, account: _policy.account, policy: _policy)
        }
      in [:as_product, *]
        let(:policy)     { create(:policy, *policy_traits, :pooled, account:, product: bearer) }
        let(:pooled_key) { create(:key, account:, policy:) }
      end

      let(:record) { pooled_key }
    end

    def accessing_its_keys(scenarios)
      case scenarios
      in [:as_product, *]
        let(:keys) {
          policy = create(:policy, *policy_traits, :pooled, account:, product: bearer)

          create_list(:key, 3, account:, policy:)
        }
      end

      let(:record) { keys }
    end

    def accessing_its_key(scenarios)
      case scenarios
      in [:as_product, *]
        let(:key) {
          policy = create(:policy, *policy_traits, :pooled, account:, product: bearer)

          create(:key, account:, policy:)
        }
      end

      let(:record) { key }
    end

    def accessing_keys(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:keys) { create_list(:key, 3, account: other_account) }
      else
        let(:keys) { create_list(:key, 3, account:) }
      end

      let(:record) { keys }
    end

    def accessing_a_key(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:key) { create(:key, account: other_account) }
      else
        let(:key) { create(:key, account:) }
      end

      let(:record) { key }
    end

    def accessing_channels(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:channels) { create_list(:channel, 3, account: other_account) }
      else
        let(:channels) { create_list(:channel, 3, account:) }
      end

      let(:record) { channels }
    end

    def accessing_a_channel(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:channel) { create(:channel, account: other_account) }
      else
        let(:channel) { create(:channel, account:) }
      end

      let(:record) { channel }
    end

    def accessing_its_channels(scenarios)
      case scenarios
      in [*, :accessing_its_product | :accessing_a_product, *]
        let(:release)   { create(:release, *release_traits, account:, product:) }
        let(:artifacts) { create_list(:artifact, 3, account:, release:) }
        let(:channels)  { artifacts.collect(&:channel) }
      in [:as_product, :accessing_itself]
        let(:release)   { create(:release, *release_traits, account:, product: bearer) }
        let(:artifacts) { create_list(:artifact, 3, account:, release:) }
        let(:channels)  { artifacts.collect(&:channel) }
      end

      let(:record) { channels }
    end

    def accessing_its_channel(scenarios)
      case scenarios
      in [*, :accessing_its_product | :accessing_a_product, *]
        let(:release)  { create(:release, *release_traits, account:, product:) }
        let(:artifact) { create(:artifact, *artifact_traits, account:, release:) }
        let(:channel)  { artifact.channel }
      in [:as_product, :accessing_itself]
        let(:release)  { create(:release, *release_traits, account:, product: bearer) }
        let(:artifact) { create(:artifact, *artifact_traits, account:, release:) }
        let(:channel)  { artifact.channel }
      end

      let(:record) { channel }
    end

    def accessing_platforms(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:platforms) { create_list(:platform, 3, account: other_account) }
      else
        let(:platforms) { create_list(:platform, 3, account:) }
      end

      let(:record) { platforms }
    end

    def accessing_a_platform(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:platform) { create(:platform, account: other_account) }
      else
        let(:platform) { create(:platform, account:) }
      end

      let(:record) { platform }
    end

    def accessing_its_platforms(scenarios)
      case scenarios
      in [*, :accessing_its_product | :accessing_a_product, *]
        let(:release)   { create(:release, *release_traits, account:, product:) }
        let(:artifacts) { create_list(:artifact, 3, account:, release:) }
        let(:platforms) { artifacts.collect(&:platform) }
      in [:as_product, :accessing_itself]
        let(:release)   { create(:release, *release_traits, account:, product: bearer) }
        let(:artifacts) { create_list(:artifact, 3, account:, release:) }
        let(:platforms) { artifacts.collect(&:platform) }
      end

      let(:record) { platforms }
    end

    def accessing_its_platform(scenarios)
      case scenarios
      in [*, :accessing_its_product | :accessing_a_product, *]
        let(:release)  { create(:release, *release_traits, account:, product:) }
        let(:artifact) { create(:artifact, *artifact_traits, account:, release:) }
        let(:platform) { artifact.platform }
      in [:as_product, :accessing_itself]
        let(:release)  { create(:release, *release_traits, account:, product: bearer) }
        let(:artifact) { create(:artifact, *artifact_traits, account:, release:) }
        let(:platform) { artifact.platform }
      end

      let(:record) { platform }
    end

    def accessing_arches(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:arches) { create_list(:arch, 3, account: other_account) }
      else
        let(:arches) { create_list(:arch, 3, account:) }
      end

      let(:record) { arches }
    end

    def accessing_an_arch(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:arch) { create(:arch, account: other_account) }
      else
        let(:arch) { create(:arch, account:) }
      end

      let(:record) { arch }
    end

    def accessing_its_arches(scenarios)
      case scenarios
      in [*, :accessing_its_product | :accessing_a_product, *]
        let(:release)   { create(:release, *release_traits, account:, product:) }
        let(:artifacts) { create_list(:artifact, 3, account:, release:) }
        let(:arches)    { artifacts.collect(&:arch) }
      in [:as_product, :accessing_itself]
        let(:release)   { create(:release, *release_traits, account:, product: bearer) }
        let(:artifacts) { create_list(:artifact, 3, account:, release:) }
        let(:arches)    { artifacts.collect(&:arch) }
      end

      let(:record) { arches }
    end

    def accessing_its_arch(scenarios)
      case scenarios
      in [*, :accessing_its_product | :accessing_a_product, *]
        let(:release)  { create(:release, *release_traits, account:, product:) }
        let(:artifact) { create(:artifact, *artifact_traits, account:, release:) }
        let(:arch)     { artifact.arch }
      in [:as_product, :accessing_itself]
        let(:release)  { create(:release, *release_traits, account:, product: bearer) }
        let(:artifact) { create(:artifact, *artifact_traits, account:, release:) }
        let(:arch)     { artifact.arch }
      end

      let(:record) { arch }
    end

    def searching(scenarios)
      case scenarios
      in [:as_admin | :as_environment | :as_product | :as_license | :as_user | :as_anonymous, *]
        let(:search_results) { create_list(:license, 3, account:) }
      end

      let(:record) { search_results }
    end
  end

  ##
  # ScenarioMethods contains scenario methods that are mixed in when
  # the AuthorizationHelper is included.
  module ScenarioMethods
    ##
    # with_role_authorization starts an authorization test for a given role.
    def with_role_authorization(role, &)
      context "with #{role} authorization" do
        using_scenario :"as_#{role}"

        let(:bearer_permissions) { nil }
        let(:token_permissions)  { nil }
        let(:account_traits)     { [] }
        let(:bearer_traits)      { [] }
        let(:token_traits)       { [] }
        let(:release_traits)     { [] }
        let(:artifact_traits)    { [] }
        let(:manifest_traits)    { [] }
        let(:descriptor_traits)  { [] }
        let(:package_traits)     { [] }
        let(:engine_traits)      { [] }
        let(:product_traits)     { [] }
        let(:policy_traits)      { [] }
        let(:license_traits)     { [] }
        let(:machine_traits)     { [] }
        let(:admin_traits)       { [] }
        let(:user_traits)        { [] }

        instance_exec(&)
      end
    end

    ##
    # without_authorization starts an authorization test for an anon.
    def without_authorization(&)
      context 'without authorization' do
        using_scenario :as_anonymous

        let(:account_traits)    { [] }
        let(:bearer_traits)     { [] }
        let(:token_traits)      { [] }
        let(:release_traits)    { [] }
        let(:artifact_traits)   { [] }
        let(:manifest_traits)   { [] }
        let(:descriptor_traits) { [] }
        let(:package_traits)    { [] }
        let(:engine_traits)     { [] }
        let(:product_traits)    { [] }
        let(:policy_traits)     { [] }
        let(:license_traits)    { [] }
        let(:machine_traits)    { [] }
        let(:admin_traits)      { [] }
        let(:user_traits)       { [] }

        instance_exec(&)
      end
    end

    private

    ##
    # using_scenarios applies a set of scenarios to the current context.
    def using_scenarios(scenarios)
      Scenarios.scenarios_for[id] ||= []

      scenarios.each do |scenario|
        method = Scenarios.instance_method(scenario)
                          .bind(self)

        if method.arity > 0
          # TODO(ezekg) Build a scenario resolver, where Rspec context [1:1] inherits scenarios
          #             from [1]. But for now, this works fine.
          #
          # For example, this merges scenarios for ./spec/policies/license_policy_spec.rb[1:1:2]
          # with scenarios for ./spec/policies/license_policy_spec.rb[1:1].
          s = Scenarios.scenarios_for.map { |k, v| v if k[..-2].in?(id[..-2]) }
                                     .flatten
                                     .compact

          instance_exec(s, &method)
        else
          instance_exec(&method)
        end

        Scenarios.scenarios_for[id] << scenario
      end
    end

    ##
    # using_scenario applies a scenario to the current context.
    def using_scenario(scenario)
      using_scenarios [scenario]
    end

    ##
    # with_scenarios applies a set of scenarios to a new context.
    def with_scenarios(scenarios, &)
      context "using #{scenarios} scenarios" do
        using_scenarios(scenarios)

        instance_exec(&)
      end
    end

    ##
    # with_scenario applies a scenario to a new context.
    def with_scenario(scenario, &)
      context "using #{scenario} scenario" do
        using_scenario(scenario)

        instance_exec(&)
      end
    end

    ##
    # with_token_authentication defines a context using token authentication.
    def with_token_authentication(&)
      context 'with token authentication' do
        let(:token) {
          environment = case bearer
                        in Environment => env
                          env
                        in environment: env
                          env
                        end

          create(:token, *token_traits, account:, bearer:, environment:, permissions: token_permissions)
        }

        instance_exec(&)
      end
    end

    ##
    # with_basic_authentication defines a context using basic authentication.
    def with_basic_authentication(&)
      context 'with basic authentication' do
        let(:token) { nil }

        instance_exec(&)
      end
    end

    ##
    # with_license_authentication defines a context using license authentication.
    def with_license_authentication(&)
      context 'with license authentication' do
        let(:token) { nil }

        it 'bearer is a license' do
          expect(bearer).to be_a License
        end

        instance_exec(&)
      end
    end

    ##
    # without_authentication defines a context using no authentication.
    def without_authentication(&)
      context 'without authentication' do
        let(:bearer) { nil }
        let(:token)  { nil }

        instance_exec(&)
      end
    end

    ##
    # with_permissions defines a context with specific bearer permisisons.
    def with_permissions(permissions, &)
      context "with #{permissions} permissions" do
        let(:bearer_permissions) { permissions }

        instance_exec(&)
      end
    end

    # without_permissions defines a context without bearer permisisons.
    def without_permissions(&)
      context "without permissions" do
        let(:bearer_permissions) { [] }

        instance_exec(&)
      end
    end

    ##
    # with_wildcard_permissions defines a context with wildcard bearer permisisons.
    def with_wildcard_permissions(&)
      context 'with wildcard permissions' do
        let(:bearer_permissions) { [Permission::WILDCARD_PERMISSION] }

        instance_exec(&)
      end
    end

    ##
    # with_default_permissions defines a context with default bearer permisisons.
    def with_default_permissions(&)
      context 'with default permissions' do
        let(:bearer_permissions) { nil }

        instance_exec(&)
      end
    end

    ##
    # with_token_permissions defines a context with specific token permisisons.
    def with_token_permissions(permissions, &)
      context "with #{permissions} token permissions" do
        let(:token_permissions) { permissions }

        instance_exec(&)
      end
    end

    ##
    # without_token_permissions defines a context without token permisisons.
    def without_token_permissions(&)
      context "without token permissions" do
        let(:token_permissions) { [] }

        instance_exec(&)
      end
    end

    ##
    # with_account_traits defines traits on the account context.
    def with_account_traits(traits, &)
      context "with account #{traits} traits" do
        let(:account_traits) { traits }

        instance_exec(&)
      end
    end

    ##
    # with_account_trait defines a trait on the account context.
    def with_account_trait(trait, &) = with_account_traits(*trait, &)

    ##
    # with_bearer_traits defines traits on the bearer context.
    def with_bearer_traits(traits, &)
      context "with bearer #{traits} traits" do
        let(:bearer_traits) { traits }

        instance_exec(&)
      end
    end

    ##
    # with_bearer_trait defines a trait on the bearer context.
    def with_bearer_trait(trait, &) = with_bearer_traits(*trait, &)

    ##
    # with_token_traits defines traits on the token context.
    def with_token_traits(traits, &)
      context "with token #{traits} traits" do
        let(:token_traits) { traits }

        instance_exec(&)
      end
    end

    ##
    # with_token_trait defines a trait on the token context.
    def with_token_trait(trait, &) = with_token_traits(*trait, &)

    ##
    # with_bearer_and_token_traits defines traits on the bearer and token contexts.
    def with_bearer_and_token_traits(traits, &)
      context "with token and bearer #{traits} traits" do
        let(:bearer_traits) { traits }
        let(:token_traits)  { traits }

        instance_exec(&)
      end
    end

    ##
    # with_bearer_and_token_trait defines a trait on the bearer and token contexts.
    def with_bearer_and_token_trait(trait, &) = with_bearer_and_token_traits(*trait, &)

    ##
    # with_release_traits defines traits on the release context.
    def with_release_traits(traits, &)
      context "with release #{traits} traits" do
        let(:release_traits) { traits }

        instance_exec(&)
      end
    end

    ##
    # with_release_trait defines a trait on the release context.
    def with_release_trait(trait, &) = with_release_traits(*trait, &)

    ##
    # with_artifact_traits defines traits on the artifact context.
    def with_artifact_traits(traits, &)
      context "with artifact #{traits} traits" do
        let(:artifact_traits) { traits }

        instance_exec(&)
      end
    end

    ##
    # with_artifact_trait defines a trait on the artifact context.
    def with_artifact_trait(trait, &) = with_artifact_traits(*trait, &)

    ##
    # with_manifest_traits defines traits on the manifest context.
    def with_manifest_traits(traits, &)
      context "with manifest #{traits} traits" do
        let(:manifest_traits) { traits }

        instance_exec(&)
      end
    end

    ##
    # with_manifest_trait defines a trait on the manifest context.
    def with_manifest_trait(trait, &) = with_manifest_traits(*trait, &)

    ##
    # with_descriptor_traits defines traits on the descriptor context.
    def with_descriptor_traits(traits, &)
      context "with descriptor #{traits} traits" do
        let(:descriptor_traits) { traits }

        instance_exec(&)
      end
    end

    ##
    # with_descriptor_trait defines a trait on the descriptor context.
    def with_descriptor_trait(trait, &) = with_descriptor_traits(*trait, &)

    ##
    # with_package_traits defines traits on the package context.
    def with_package_traits(traits, &)
      context "with package #{traits} traits" do
        let(:package_traits) { traits }

        instance_exec(&)
      end
    end

    ##
    # with_package_trait defines a trait on the package context.
    def with_package_trait(trait, &) = with_package_traits(*trait, &)

    ##
    # with_engine_traits defines traits on the engine context.
    def with_engine_traits(traits, &)
      context "with engine #{traits} traits" do
        let(:engine_traits) { traits }

        instance_exec(&)
      end
    end

    ##
    # with_engine_trait defines a trait on the engine context.
    def with_engine_trait(trait, &) = with_engine_traits(*trait, &)

    ##
    # with_product_traits defines traits on the product context.
    def with_product_traits(traits, &)
      context "with product #{traits} traits" do
        let(:product_traits) { traits }

        instance_exec(&)
      end
    end

    ##
    # with_product_trait defines a trait on the product context.
    def with_product_trait(trait, &) = with_product_traits(*trait, &)

    ##
    # with_policy_traits defines traits on the policy context.
    def with_policy_traits(traits, &)
      context "with policy #{traits} traits" do
        let(:policy_traits) { traits }

        instance_exec(&)
      end
    end

    ##
    # with_policy_trait defines a trait on the policy context.
    def with_policy_trait(trait, &) = with_policy_traits(*trait, &)

    ##
    # with_license_traits defines traits on the license context.
    def with_license_traits(traits, &)
      context "with license #{traits} traits" do
        let(:license_traits) { traits }

        instance_exec(&)
      end
    end

    ##
    # with_license_trait defines a trait on the license context.
    def with_license_trait(trait, &) = with_license_traits(*trait, &)

    ##
    # with_machine_traits defines traits on the machine context.
    def with_machine_traits(traits, &)
      context "with machine #{traits} traits" do
        let(:machine_traits) { traits }

        instance_exec(&)
      end
    end

    ##
    # with_machine_trait defines a trait on the machine context.
    def with_machine_trait(trait, &) = with_machine_traits(*trait, &)

    ##
    # with_admin_traits defines traits on the admin context.
    def with_admin_traits(traits, &)
      context "with admin #{traits} traits" do
        let(:admin_traits) { traits }

        instance_exec(&)
      end
    end

    ##
    # with_admin_trait defines a trait on the admin context.
    def with_admin_trait(trait, &) = with_admin_traits(*trait, &)

    ##
    # with_user_traits defines traits on the user context.
    def with_user_traits(traits, &)
      context "with user #{traits} traits" do
        let(:user_traits) { traits }

        instance_exec(&)
      end
    end

    ##
    # with_user_trait defines a trait on the user context.
    def with_user_trait(trait, &) = with_user_traits(*trait, &)

    ##
    # with_account_protection enables account protection.
    def with_account_protection(&)
      with_account_traits %i[protected] do
        instance_exec(&)
      end
    end

    ##
    # without_account_protection disables account protection.
    def without_account_protection(&)
      with_account_traits %i[unprotected] do
        instance_exec(&)
      end
    end

    ##
    # allows asserts the current bearer and token are permitted to perform
    # the given actions.
    def allows(*actions)
      actions.flatten.each do |action|
        it "should allow #{action.inspect}" do
          expect(subject).to authorize(action)
        end
      end
    end

    ##
    # denies asserts the current bearer and token are not permitted to perform
    # the given actions.
    def denies(*actions)
      actions.flatten.each do |action|
        it "should deny #{action.inspect}" do
          expect(subject).to_not authorize(action)
        end
      end
    end

    ##
    # pp prints all let() vars that are defined in the current context, and also
    # prints vars when accessed, for debugging purposes. This ONLY prints vars
    # defined in the current context, not parent or child contexts. Using
    # :verbose will also print the var's value when accessed.
    def pp(except: nil, only: nil, verbose: false)
      mod = RSpec::Core::MemoizedHelpers.module_for(self)

      mod.instance_methods.each do |var|
        next if
          except.present? && var.in?(Array(except)) ||
          only.present? && !var.in?(Array(only))

        $stderr.puts "[pp] set=#{var}"

        meth = mod.instance_method(var)

        mod.define_method var do
          val = meth.bind(self).call

          if verbose
            $stderr.puts "[pp] get=#{var} val=#{val.inspect}"
          else
            $stderr.puts "[pp] get=#{var}"
          end

          val
        end
      end
    end
  end

  ##
  # included mixes in ScenarioMethods on include.
  def self.included(klass)
    klass.extend ScenarioMethods
  end
end
