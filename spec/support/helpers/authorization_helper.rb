# frozen_string_literal: true

module AuthorizationHelper
  ##
  # Scenarios contains predefined scenarios to keep spec files clean and
  # easy to write (for security's sake) using pattern matching.
  module Scenarios
    ##
    # scenarios_for keeps track of scenarios by Rspec contexts.
    cattr_accessor :scenarios_for, default: {}

    def as_admin(scenarios)
      case scenarios
      in []
        let(:account) { create(:account) }
        let(:bearer)  { create(:admin, account:, permissions: bearer_permissions) }
        let(:admin)   { bearer }
      end
    end

    def as_product(scenarios)
      case scenarios
      in []
        let(:account) { create(:account) }
        let(:bearer)  { create(:product, account:, permissions: bearer_permissions) }
        let(:product) { bearer }
      end
    end

    def as_license(scenarios)
      case scenarios
      in []
        let(:account) { create(:account) }
        let(:bearer)  { create(:license, account:, permissions: bearer_permissions) }
        let(:license) { bearer }
      end
    end

    def as_user(scenarios)
      case scenarios
      in []
        let(:account) { create(:account) }
        let(:bearer)  { create(:user, account:, permissions: bearer_permissions) }
        let(:user)    { bearer }
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

    def with_licenses(scenarios)
      case scenarios
      in [:as_user, *]
        let(:licenses) { create_list(:license, 2, account:, user: bearer) }
      end
    end

    def accessing_itself(scenarios)
      case scenarios
      in [:as_admin | :as_product | :as_license | :as_user, *]
        let(:record) { bearer }
      end
    end

    def accessing_another_account(scenarios)
      case scenarios
      in [:as_admin | :as_product | :as_license | :as_user, *]
        let(:other_account) { create(:account) }
      end
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
      in [:as_license, *]
        let(:product) { bearer.product }
      in [:as_user, *]
        let(:product) { licenses.first.product }
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

    def accessing_its_tokens(scenarios)
      case scenarios
      in [*, :accessing_its_product | :accessing_a_product, *]
        let(:tokens)   { create_list(:token, 3, account: product.account, bearer: product) }
      in [*, :accessing_itself, *]
        let(:tokens)   { create_list(:token, 3, account: bearer.account, bearer:) }
      end

      let(:record) { tokens }
    end

    def accessing_its_token(scenarios)
      case scenarios
      in [*, :accessing_its_product | :accessing_a_product, *]
        let(:_token) { create(:token, account: product.account, bearer: product) }
      in [*, :accessing_itself, *]
        let(:_token) { create(:token, account: bearer.account, bearer:) }
      end

      let(:record) { _token }
    end

    def accessing_a_license(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:license) { create(:license, account: other_account) }
      else
        let(:license) { create(:license, account:) }
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
      in [:as_user, :with_licenses, *]
        let(:license) { licenses.first }
      end

      let(:record) { license }
    end

    def accessing_its_users(scenarios)
      case scenarios
      in [:as_product, :accessing_a_group, *]
        let(:policy)    { create(:policy, account:, product: bearer) }
        let(:users)     { create_list(:user, 3, account:, group:) }
        let!(:licenses) { users.map { create(:license, account:, policy:, user: _1) } }
      in [*, :accessing_its_group | :accessing_a_group, *]
        let(:users) { create_list(:user, 3, account: group.account, group:) }
      end

      let(:record) { users }
    end

    def accessing_its_user(scenarios)
      case scenarios
      in [:as_product, :accessing_a_group, *]
        let(:policy)  { create(:policy, account:, product: bearer) }
        let(:user)    { create(:user, account:, group:) }
        let(:license) { create(:license, account:, policy:, user:) }
      in [*, :accessing_its_group | :accessing_a_group, *]
        let(:user) { create(:user, account: group.account, group:) }
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
      in [:as_user, :with_licenses, *]
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
      in [*, :accessing_its_license | :accessing_a_license, *]
        let(:entitlements)         { create_list(:entitlement, 3, account: license.account) }
        let(:license_entitlements) { entitlements.map { create(:license_entitlement, account: license.account, license:, entitlement: _1) } }
      in [:as_license, *]
        let(:entitlements)         { create_list(:entitlement, 3, account:) }
        let(:license_entitlements) { entitlements.map { create(:license_entitlement, account:, license: bearer, entitlement: _1) } }
      in [:as_user, :with_licenses, *]
        let(:entitlements)         { create_list(:entitlement, 3, account:) }
        let(:license_entitlements) { entitlements.map { create(:license_entitlement, account:, license: licenses.first, entitlement: _1) } }
      end

      let(:record) { license_entitlements.collect(&:entitlement) }
    end

    def accessing_its_entitlement(scenarios)
      case scenarios
      in [*, :accessing_its_license | :accessing_a_license, *]
        let(:entitlement)         { create(:entitlement, account: license.account) }
        let(:license_entitlement) { create(:license_entitlement, account: license.account, license:, entitlement:) }
      in [:as_license, *]
        let(:entitlement)         { create(:entitlement, account:) }
        let(:license_entitlement) { create(:license_entitlement, account:, license: bearer, entitlement:) }
      in [:as_user, :with_licenses, *]
        let(:entitlement)         { create(:entitlement, account:) }
        let(:license_entitlement) { create(:license_entitlement, account:, license: licenses.first, entitlement:) }
      end

      let(:record) { license_entitlement.entitlement }
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
      in [:as_user, :with_licenses, *]
        let(:machines) { create_list(:machine, 3, account:, license: licenses.first) }
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
      in [:as_user, :with_licenses, *]
        let(:machine) { create(:machine, account:, license: licenses.first) }
      end

      let(:record) { machine }
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
  end

  ##
  # included mixes in ClassMethods on include.
  def self.included(klass)
    klass.extend ClassMethods
  end
end
