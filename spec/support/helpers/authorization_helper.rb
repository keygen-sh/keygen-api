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

    def accessing_its_license(scenarios)
      case scenarios
      in [:as_product, *]
        let(:policy)  { create(:policy, account:, product: bearer)}
        let(:license) { create(:license, account:, policy:) }
      in [:as_user, :with_licenses, *]
        let(:license) { licenses.first }
      end

      let(:record) { license }
    end

    def accessing_its_group(scenarios)
      case scenarios
      in [*, :accessing_another_account, :accessing_a_license, *]
        let(:group) { create(:group, account: other_account, licenses: [license]) }
      in [*, :accessing_its_license | :accessing_a_license, *]
        let(:group) { create(:group, account:, licenses: [license]) }
      in [:as_license, :accessing_itself, *]
        let(:group) { create(:group, account:, licenses: [bearer]) }
      end

      let(:record) { group }
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
