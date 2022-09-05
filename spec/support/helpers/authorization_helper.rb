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
        let(:account) { create(:account) }
        let(:bearer)  { create(:admin, account:, permissions: bearer_permissions) }
      end
    end

    def as_product(scenarios)
      case scenarios
      in []
        let(:account) { create(:account) }
        let(:bearer)  { create(:product, account:, permissions: bearer_permissions) }
      end
    end

    def as_license(scenarios)
      case scenarios
      in []
        let(:account)      { create(:account) }
        let(:policy)       { create(:policy, account:) }
        let(:license_user) { nil }
        let(:expiry)       { nil }
        let(:bearer)       { create(:license, account:, policy:, user: license_user, expiry:, permissions: bearer_permissions) }
      end
    end

    def as_user(scenarios)
      case scenarios
      in []
        let(:account) { create(:account) }
        let(:bearer)  { create(:user, account:, permissions: bearer_permissions) }
      end
    end

    def as_group_owner(scenarios)
      case scenarios
      in [:as_user, :accessing_a_group, *]
        let!(:group_owner) { create(:group_owner, account:, group:, user: bearer) }
      end
    end

    def as_anonymous(scenarios)
      let(:account) { create(:account) }
      let(:bearer)  { nil }
    end

    ##
    # is_* matchers for mutating the current :bearer state or its relations. Typically,
    # these will set let() vars that are used by the :bearer, but they can also define
    # new relations, such as with %i[as_user is_licensed]. Common to use let!() to
    # define vars that may or may not be accessed directly.
    def is_expired(scenarios)
      case scenarios
      in [:as_license, *]
        let(:expiry) { 1.year.ago }
      in [:as_user, :is_licensed, *]
        let(:expiry) { 1.year.ago }
      end
    end

    def is_allowed_access(scenarios)
      case scenarios
      in [:as_license, :is_expired, *]
        let(:policy) { create(:policy, account:, expiration_strategy: 'ALLOW_ACCESS') }
      in [:as_user, :is_licensed, :is_expired, *]
        let(:policy) { create(:policy, account:, expiration_strategy: 'ALLOW_ACCESS') }
      end
    end

    def is_within_access_window(scenarios)
      case scenarios
      in [:as_license, :is_expired, *]
        # noop
      in [:as_user, :is_licensed, :is_expired, *]
        # noop
      end
    end

    def is_licensed(scenarios)
      case scenarios
      in [:as_user, *]
        let(:expiry)   { nil }
        let(:licenses) { create_list(:license, 2, account:, expiry:, user: bearer) }
        let(:license)  { licenses.first }
      end
    end

    def is_entitled(scenarios)
      case scenarios
      in [:as_license, *]
        let(:entitlements)          { create_list(:entitlement, 6, account:) }
        let!(:license_entitlements) { entitlements[..2].map { create(:license_entitlement, account:, license: bearer, entitlement: _1) } }
        let!(:policy_entitlements)  { entitlements[3..].map { create(:policy_entitlement, account:, policy: bearer.policy, entitlement: _1) } }
      in [:as_user, :is_licensed, *]
        let(:entitlements)          { create_list(:entitlement, 6, account:) }
        let!(:license_entitlements) { entitlements[..2].map { create(:license_entitlement, account:, license:, entitlement: _1) } }
        let!(:policy_entitlements)  { entitlements[3..].map { create(:policy_entitlement, account:, policy: license.policy, entitlement: _1) } }
      end
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

    def accessing_another_account(scenarios)
      case scenarios
      in [:as_admin | :as_product | :as_license | :as_user, *]
        let(:other_account) { create(:account) }
      end
    end

    def accessing_an_account(scenarios)
      case scenarios
      in [:as_admin | :as_product | :as_license | :as_user | :as_anonymous, *]
        let(:_account) { create(:account) }
      end

      let(:record) { _account }
    end

    def accessing_its_account(scenarios)
      case scenarios
      in [:as_admin | :as_product | :as_license | :as_user, *]
        # noop
      end

      let(:record) { account }
    end

    def accessing_a_product(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:product) { create(:product, account: other_account) }
      else
        let(:product) { create(:product, account:) }
      end

      let(:record) { product }
    end

    def accessing_its_product(scenarios)
      case scenarios
      in [*, :accessing_its_license | :accessing_a_license, *]
        let(:product) { license.product }
      in [:as_license, *]
        let(:product) { bearer.product }
      in [:as_user, :is_licensed, *]
        let(:product) { license.product }
      end

      let(:record) { product }
    end

    def accessing_products(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:products) { [create(:product, account: other_account)] }
      else
        let(:products) { [create(:product, account:)] }
      end

      let(:record) { products }
    end

    def accessing_its_products(scenarios)
      case scenarios
      in [:as_license, *]
        let(:products) { [bearer.product] }
      in [:as_user, *]
        let(:products) { licenses.collect(&:product) }
      end

      let(:record) { products }
    end

    def accessing_policies(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:policies) { create_list(:policy, 3, account: other_account) }
      else
        let(:policies) { create_list(:policy, 3, account:) }
      end

      let(:record) { policies }
    end

    def accessing_a_policy(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:_policy) { create(:policy, account: other_account) }
      else
        let(:_policy) { create(:policy, account:) }
      end

      let(:record) { _policy }
    end

    def accessing_its_policies(scenarios)
      case scenarios
      in [:as_product, *]
        let(:policies) { create_list(:policy, 3, account: bearer.account, product: bearer) }
      in [:as_license, *]
        let(:policies) { [bearer.policy] }
      in [:as_user, :is_licensed, *]
        let(:policies) { licenses.collect(&:policy) }
      end

      let(:record) { policies }
    end

    def accessing_its_policy(scenarios)
      case scenarios
      in [*, :accessing_its_license | :accessing_a_license, *]
        let(:_policy) { license.policy }
      in [:as_product, *]
        let(:_policy) { create(:policy, account: bearer.account, product: bearer) }
      in [:as_license, *]
        let(:_policy) { bearer.policy }
      in [:as_user, :is_licensed, *]
        let(:_policy) { license.policy }
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
            create(:token, account:, bearer: create(:product, account:)),
            create(:token, account:, bearer: create(:license, account:)),
            create(:token, account:, bearer: create(:user, account:)),
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
      in [*, :accessing_itself, *]
        let(:tokens)   { create_list(:token, 3, account: bearer.account, bearer:) }
      in [:as_admin | :as_product | :as_license | :as_user, *]
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
      in [*, :accessing_itself, *]
        let(:_token) { create(:token, account: bearer.account, bearer:) }
      in [:as_admin | :as_product | :as_license | :as_user, *]
        let(:_token) { create(:token, account: bearer.account, bearer:) }
      end

      let(:record) { _token }
    end

    def accessing_admins(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:admins) { create_list(:admin, 3, account: other_account) }
      else
        let(:admins) { create_list(:admin, 3, account:) }
      end

      let(:record) { admins }
    end

    def accessing_an_admin(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:admin) { create(:admin, account: other_account) }
      else
        let(:admin) { create(:admin, account:) }
      end

      let(:record) { admin }
    end

    def accessing_users(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:users) { create_list(:user, 3, account: other_account) }
      else
        let(:users) { create_list(:user, 3, account:) }
      end

      let(:record) { users }
    end

    def accessing_a_user(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:user) { create(:user, account: other_account) }
      else
        let(:user) { create(:user, account:) }
      end

      let(:record) { user }
    end

    def accessing_its_users(scenarios)
      case scenarios
      in [:as_product, :accessing_a_group, *]
        let(:policy)    { create(:policy, account:, product: bearer) }
        let(:users)     { create_list(:user, 3, account:, group:) }
        let!(:licenses) { users.map { create(:license, account:, policy:, user: _1) } }
      in [*, :accessing_its_group | :accessing_a_group, *]
        let(:users) { create_list(:user, 3, account: group.account, group:) }
      in [:as_product, *]
        let(:policy)    { create(:policy, account:, product: bearer) }
        let(:users)     { create_list(:user, 3, account:) }
        let!(:licenses) { users.map { create(:license, account:, policy:, user: _1) } }
      end

      let(:record) { users }
    end

    def accessing_its_user(scenarios)
      case scenarios
      in [*, :accessing_its_license | :accessing_a_license, *]
        let(:user) { license.user }
      in [:as_product, :accessing_a_group, *]
        let(:policy)  { create(:policy, account:, product: bearer) }
        let(:user)    { create(:user, account:, group:) }
        let(:license) { create(:license, account:, policy:, user:) }
      in [*, :accessing_its_group | :accessing_a_group, *]
        let(:user) { create(:user, account: group.account, group:) }
      in [:as_product, *]
        let(:policy)   { create(:policy, account:, product: bearer) }
        let(:user)     { create(:user, account:) }
        let!(:license) { create(:license, account:, policy:, user:) }
      in [:as_license, :with_user, *]
        let(:user) { bearer.user }
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
      in [:as_user, :is_licensed, *]
        let(:groups) { [create(:group, account:, users: [bearer]), *licenses.map(&:group)] }
      in [:as_user, *]
        let(:groups) { [create(:group, account:, users: [bearer])] }
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
      in [*, :accessing_its_license | :accessing_a_license, :with_entitlements, *]
        # noop
      in [*, :accessing_its_policy | :accessing_a_policy, :with_entitlements, *]
        # noop
      in [:as_license, :is_entitled, *]
        # noop
      in [:as_user, :is_licensed, :is_entitled, *]
        # noop
      end

      let(:record) { entitlements }
    end

    def accessing_its_entitlement(scenarios)
      case scenarios
      in [*, :accessing_its_license | :accessing_a_license, *]
        let(:entitlement)          { create(:entitlement, account: license.account) }
        let!(:license_entitlement) { create(:license_entitlement, account: license.account, license:, entitlement:) }
      in [*, :accessing_its_policy | :accessing_a_policy, *]
        let(:entitlement)         { create(:entitlement, account: _policy.account) }
        let!(:policy_entitlement) { create(:policy_entitlement, account: _policy.account, policy: _policy, entitlement:) }
      in [:as_license, :is_entitled, *]
        let(:entitlement) { entitlements.first }
      in [:as_user, :is_licensed, :is_entitled, *]
        let(:entitlement) { entitlements.first }
      end

      let(:record) { entitlement }
    end

    def accessing_machines(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:machines) { create_list(:machine, 3, account: other_account) }
      else
        let(:machines) { create_list(:machine, 3, account:) }
      end

      let(:record) { machines }
    end

    def accessing_a_machine(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:machine) { create(:machine, account: other_account) }
      else
        let(:machine) { create(:machine, account:) }
      end

      let(:record) { machine }
    end

    def accessing_its_machines(scenarios)
      case scenarios
      in [*, :accessing_its_license | :accessing_a_license, *]
        let(:machines) { create_list(:machine, 3, account: license.account, license:) }
      in [:as_product, :accessing_a_group, *]
        let(:policy)   { create(:policy, account:, product: bearer) }
        let(:license)  { create(:license, account:, policy:) }
        let(:machines) { create_list(:machine, 3, account:, license:, group:) }
      in [*, :accessing_its_group | :accessing_a_group, *]
        let(:machines) { create_list(:machine, 3, account: group.account, group:) }
      in [:as_product, *]
        let(:policy)   { create(:policy, account:, product: bearer) }
        let(:license)  { create(:license, account:, policy:) }
        let(:machines) { create_list(:machine, 3, account:, license:) }
      in [:as_license, *]
        let(:machines) { create_list(:machine, 3, account:, license: bearer) }
      in [:as_user, :is_licensed, *]
        let(:machines) { create_list(:machine, 3, account:, license:) }
      end

      let(:record) { machines }
    end

    def accessing_its_machine(scenarios)
      case scenarios
      in [*, :accessing_its_license | :accessing_a_license, *]
        let(:machine) { create(:machine, account: license.account, license:) }
      in [:as_product, :accessing_a_group, *]
        let(:policy)  { create(:policy, account:, product: bearer) }
        let(:license) { create(:license, account:, policy:) }
        let(:machine) { create(:machine, account:, license:, group:) }
      in [*, :accessing_its_group | :accessing_a_group, *]
        let(:machine) { create(:machine, account: group.account, group:) }
      in [:as_product, *]
        let(:policy)  { create(:policy, account:, product: bearer) }
        let(:license) { create(:license, account:, policy:) }
        let(:machine) { create(:machine, account:, license:) }
      in [:as_license, *]
        let(:machine) { create(:machine, account:, license: bearer) }
      in [:as_user, :is_licensed, *]
        let(:machine) { create(:machine, account:, license:) }
      end

      let(:record) { machine }
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
      in [:as_product, *]
        let(:policy)            { create(:policy, account:, product: bearer) }
        let(:license)           { create(:license, account:, policy:) }
        let(:machine)           { create(:machine, account:, license:) }
        let(:machine_processes) { create_list(:machine_process, 3, account:, machine:) }
      in [:as_license, *]
        let(:machine)           { create(:machine, account:, license: bearer) }
        let(:machine_processes) { create_list(:process, 3, account:, machine:) }
      in [:as_user, :is_licensed, *]
        let(:machine)           { create(:machine, account:, license:) }
        let(:machine_processes) { create_list(:process, 3, account:, machine:) }
      end

      let(:record) { machine_processes }
    end

    def accessing_its_machine_process(scenarios)
      case scenarios
      in [:as_product, *]
        let(:policy)          { create(:policy, account:, product: bearer) }
        let(:license)         { create(:license, account:, policy:) }
        let(:machine)         { create(:machine, account:, license:) }
        let(:machine_process) { create(:process, account:, machine:) }
      in [:as_license, *]
        let(:machine)         { create(:machine, account:, license: bearer) }
        let(:machine_process) { create(:process, account:, machine:) }
      in [:as_user, :is_licensed, *]
        let(:machine)         { create(:machine, account:, license:) }
        let(:machine_process) { create(:process, account:, machine:) }
      end

      let(:record) { machine_process }
    end

    def accessing_its_owners(scenarios)
      case scenarios
      in [*, :accessing_a_group, :as_group_owner, *]
        let(:group_owners) { create_list(:group_owner, 3, account: group.account, group:) << group_owner }
      in [*, :accessing_its_group | :accessing_a_group, *]
        let(:group_owners) { create_list(:group_owner, 3, account: group.account, group:) }
      end

      let(:record) { group_owners }
    end

    def accessing_its_owner(scenarios)
      case scenarios
      in [*, :accessing_a_group, :as_group_owner, *]
        let(:_group_owner) { create(:group_owner, account: group.account, group:) }
      in [*, :accessing_its_group | :accessing_a_group, *]
        let(:_group_owner) { create(:group_owner, account: group.account, group:) }
      end

      let(:record) { _group_owner }
    end

    def accessing_releases(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:releases) { create_list(:release, 3, account: other_account) }
      else
        let(:releases) { create_list(:release, 3, account:) }
      end

      let(:record) { releases }
    end

    def accessing_a_release(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:release) { create(:release, account: other_account) }
      else
        let(:release) { create(:release, account:) }
      end

      let(:record) { release }
    end

    def accessing_its_releases(scenarios)
      case scenarios
      in [:as_product, *]
        let(:releases) { create_list(:release, 3, account:, product: bearer) }
      in [:as_license, *]
        let(:releases) { create_list(:release, 3, account:, product: bearer.product) }
      in [:as_user, :is_licensed, *]
        let(:releases) { licenses.map { create(:release, account:, product: _1.product) } }
      end

      let(:record) { releases }
    end

    def accessing_its_release(scenarios)
      case scenarios
      in [:as_product, *]
        let(:release) { create(:release, account:, product: bearer) }
      in [:as_license, :is_expired, :is_within_access_window, *]
        let(:release) { create(:release, account:, product: bearer.product, created_at: bearer.expiry - 1.day) }
      in [:as_license, *]
        let(:release) { create(:release, account:, product: bearer.product) }
      in [:as_user, :is_licensed, :is_expired, :is_within_access_window, *]
        let(:release) { create(:release, account:, product: license.product, created_at: license.expiry - 1.day) }
      in [:as_user, :is_licensed, *]
        let(:release) { create(:release, account:, product: license.product) }
      end

      let(:record) { release }
    end

    def accessing_artifacts(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:artifacts) { create_list(:release_artifact, 3, account: other_account) }
      else
        let(:artifacts) { create_list(:release_artifact, 3, account:) }
      end

      let(:record) { artifacts }
    end

    def accessing_an_artifact(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:artifact) { create(:release_artifact, account: other_account) }
      else
        let(:artifact) { create(:release_artifact, account:) }
      end

      let(:record) { artifact }
    end

    def accessing_its_artifacts(scenarios)
      case scenarios
      in [:as_product, *]
        let(:releases)  { create_list(:release, 3, account:, product: bearer) }
        let(:artifacts) { releases.map { create(:release_artifact, account:, release: _1) } }
      in [:as_license, *]
        let(:releases)  { create_list(:release, 3, account:, product: bearer.product) }
        let(:artifacts) { releases.map { create(:release_artifact, account:, release: _1) } }
      in [:as_user, :is_licensed, *]
        let(:releases)  { licenses.map { create(:release, account:, product: _1.product) } }
        let(:artifacts) { releases.map { create(:release_artifact, account:, release: _1) } }
      end

      let(:record) { artifacts }
    end

    def accessing_its_artifact(scenarios)
      case scenarios
      in [:as_product, *]
        let(:release)  { create(:release, account:, product: bearer) }
        let(:artifact) { create(:release_artifact, account:, release:) }
      in [:as_license, *]
        let(:release)  { create(:release, account:, product: bearer.product) }
        let(:artifact) { create(:release_artifact, account:, release:) }
      in [:as_user, :is_licensed, *]
        let(:release)  { create(:release, account:, product: license.product) }
        let(:artifact) { create(:release_artifact, account:, release:) }
      end

      let(:record) { artifact }
    end

    def accessing_licenses(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:licenses) { create_list(:license, 3, account: other_account) }
      else
        let(:licenses) { create_list(:license, 3, account:) }
      end

      let(:record) { licenses }
    end

    def accessing_a_license(scenarios)
      let(:license_user) { nil }

      case scenarios
      in [*, :accessing_another_account, *]
        let(:license) { create(:license, user: license_user, account: other_account) }
      else
        let(:license) { create(:license, user: license_user, account:) }
      end

      let(:record) { license }
    end

    def accessing_its_licenses(scenarios)
      case scenarios
      in [:as_product, :accessing_a_group, *]
        let(:policy)   { create(:policy, account:, product: bearer) }
        let(:licenses) { create_list(:license, 3, account:, policy:, group:) }
      in [*, :accessing_its_group | :accessing_a_group, *]
        let(:licenses) { create_list(:license, 3, account: group.account, group:) }
      in [:as_product, *]
        let(:policy)   { create(:policy, account:, product: bearer) }
        let(:licenses) { create_list(:license, 3, account:, policy:) }
      in [:as_user, :is_licensed, *]
        # noop
      end

      let(:record) { licenses }
    end

    def accessing_its_license(scenarios)
      case scenarios
      in [:as_product, :accessing_a_group, *]
        let(:policy)  { create(:policy, account:, product: bearer) }
        let(:license) { create(:license, account:, policy:, group:) }
      in [*, :accessing_its_group | :accessing_a_group, *]
        let(:license) { create(:license, account: group.account, group:) }
      in [:as_product, *]
        let(:policy)  { create(:policy, account:, product: bearer) }
        let(:license) { create(:license, account:, policy:) }
      in [:as_user, :is_licensed, *]
        # noop
      end

      let(:record) { license }
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
      end

      let(:record) { pooled_key }
    end

    ##
    # with_* scenarios for mutating the state of and relations for the current :record.
    # Typically, these will act upon an existing named record, e.g. :license. Also
    # common for these scenarios to use let!(), since the vars may not be accessed
    # directly, e.g. such as for :with_entitlements and :with_constrants.
    def with_entitlements(scenarios)
      case scenarios
      in [*, :accessing_its_license | :accessing_a_license, *]
        let(:entitlements)          { create_list(:entitlement, 6, account: license.account) }
        let!(:policy_entitlements)  { entitlements[3..].map { create(:policy_entitlement, account: license.account, policy: license.policy, entitlement: _1) } }
        let!(:license_entitlements) { entitlements[..2].map { create(:license_entitlement, account: license.account, license:, entitlement: _1) } }
      in [*, :accessing_its_policy | :accessing_a_policy, *]
        let(:entitlements)          { create_list(:entitlement, 3, account: _policy.account) }
        let!(:policy_entitlements)  { entitlements.map { create(:policy_entitlement, account: _policy.account, policy: _policy, entitlement: _1) } }
        let!(:license_entitlements) { [] }
      end
    end

    def with_constraints(scenarios)
      case scenarios
      in [*, :is_entitled, :accessing_its_release | :accessing_a_release, *]
        let!(:constraints) { entitlements.map { create(:release_entitlement_constraint, account: release.account, entitlement: _1, release:) } }
      in [*, :accessing_its_release | :accessing_a_release, *]
        let!(:constraints) { create_list(:release_entitlement_constraint, 3, account: release.account, release:) }
      end
    end

    def with_user(scenarios)
      case scenarios
      in [*, :accessing_another_account, :accessing_a_license, *]
        let(:license_user) { create(:user, account: other_account) }
      in [*, :accessing_its_license | :accessing_a_license, *]
        let(:license_user) { create(:user, account:) }
      in [:as_license, *]
        let(:license_user) { create(:user, account:) }
      end
    end
  end

  ##
  # ClassMethods contains class methods that are mixed in when
  # the AuthorizationHelper is included.
  module ClassMethods
    ##
    # with_role_authorization starts an authorization test for a given role.
    def with_role_authorization(role, &)
      context "with #{role} authorization" do
        using_scenario :"as_#{role}"

        let(:bearer_permissions) { nil }
        let(:token_permissions)  { nil }

        instance_exec(&)
      end
    end

    ##
    # without_authorization starts an authorization test for an anon.
    def without_authorization(&)
      context 'without authorization' do
        using_scenario :as_anonymous

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
        let(:token) { create(:token, account:, bearer:, permissions: token_permissions) }

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
    # with_account_protection enables account protection.
    def with_account_protection(&)
      context "with account protection" do
        let(:account) { create(:account, :protected) }

        instance_exec(&)
      end
    end

    ##
    # without_account_protection disables account protection.
    def without_account_protection(&)
      context "without account protection" do
        let(:account) { create(:account, :unprotected) }

        instance_exec(&)
      end
    end

    ##
    # allows asserts the current bearer and token are permitted to perform
    # the given actions.
    def allows(*actions)
      actions.flatten.each do |action|
        it "should allow #{action}" do
          expect(subject).to authorize(action)
        end
      end
    end

    ##
    # denies asserts the current bearer and token are not permitted to perform
    # the given actions.
    def denies(*actions)
      actions.flatten.each do |action|
        it "should deny #{action}" do
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
  # included mixes in ClassMethods on include.
  def self.included(klass)
    klass.extend ClassMethods
  end
end
