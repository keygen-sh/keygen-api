# frozen_string_literal: true

module AuthorizationHelper
  ##
  # Scenarios contains predefined scenarios to keep spec files clean and
  # easy to write, for security's sake.
  module Scenarios
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
        let(:account) { create(:account) }
        let(:bearer)  { create(:license, account:, permissions: bearer_permissions) }
      end
    end

    def as_user(scenarios)
      case scenarios
      in []
        let(:account) { create(:account) }
        let(:bearer)  { create(:user, account:, permissions: bearer_permissions) }
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
        let(:resource) { authorization_resource(subject: bearer) }
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

      let(:resource) { authorization_resource(subject: product) }
    end

    def accessing_its_product(scenarios)
      case scenarios
      in [:as_license, *]
        let(:product) { bearer.product }
      in [:as_user, *]
        let(:product) { licenses.first.product }
      end

      let(:resource) { authorization_resource(subject: product) }
    end

    def accessing_products(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:products) { [create(:product, account: other_account)] }
      else
        let(:products) { [create(:product, account:)] }
      end

      let(:resource) { authorization_resource(subject: products) }
    end

    def accessing_its_products(scenarios)
      case scenarios
      in [:as_license, *]
        let(:products) { [bearer.product] }
      in [:as_user, *]
        let(:products) { licenses.collect(&:product) }
      end

      let(:resource) { authorization_resource(subject: products) }
    end

    def accessing_its_tokens(scenarios)
      case scenarios
      in [*, :accessing_its_product | :accessing_a_product, *]
        let(:tokens)   { create_list(:token, 3, account: product.account, bearer: product) }
        let(:resource) { authorization_resource(subject: tokens, context: [product]) }
      in [*, :accessing_itself, *]
        let(:tokens)   { create_list(:token, 3, account: bearer.account, bearer:) }
        let(:resource) { authorization_resource(subject: tokens, context: [bearer]) }
      end
    end

    def accessing_its_token(scenarios)
      case scenarios
      in [*, :accessing_its_product | :accessing_a_product, *]
        let(:_token)   { create(:token, account: product.account, bearer: product) }
        let(:resource) { authorization_resource(subject: _token, context: [product]) }
      in [*, :accessing_itself, *]
        let(:_token)   { create(:token, account: bearer.account, bearer:) }
        let(:resource) { authorization_resource(subject: _token, context: [bearer]) }
      end
    end

    def accessing_a_license(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:license) { create(:license, account: other_account) }
      else
        let(:license) { create(:license, account:) }
      end

      let(:resource) { authorization_resource(subject: license) }
    end

    def accessing_its_license(scenarios)
      case scenarios
      in [:as_product, *]
        let(:policy)  { create(:policy, account:, product: bearer)}
        let(:license) { create(:license, account:, policy:) }
      in [:as_user, :with_licenses, *]
        let(:license) { licenses.first }
      end

      let(:resource) { authorization_resource(subject: license) }
    end

    def accessing_its_group(scenarios)
      case scenarios
      in [*, :accessing_another_account, :accessing_a_license, *]
        let(:group)    { create(:group, account: other_account, licenses: [license]) }
        let(:resource) { authorization_resource(subject: group, context: [license]) }
      in [*, :accessing_its_license | :accessing_a_license, *]
        let(:group)    { create(:group, account:, licenses: [license]) }
        let(:resource) { authorization_resource(subject: group, context: [license]) }
      in [:as_license, :accessing_itself, *]
        let(:group)    { create(:group, account:, licenses: [bearer]) }
        let(:resource) { authorization_resource(subject: group, context: [bearer]) }
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
        let(:context)            { authorization_context(account:, bearer:, token:) }
        let(:bearer_permissions) { nil }
        let(:token_permissions)  { nil }

        instance_exec(&)
      end
    end

    ##
    # without_authorization starts an authorization test for an anon.
    def without_authorization(&)
      context 'without authorization' do
        let(:context) { authorization_context(account:, bearer:, token:) }

        instance_exec(&)
      end
    end

    private

    ##
    # using_scenarios applies a set of scenarios to the current context.
    def using_scenarios(scenarios)
      scenarios.reduce [] do |accum, scenario|
        method = Scenarios.instance_method(scenario)
                          .bind(self)

        if method.arity > 0
          instance_exec(accum, &method)
        else
          instance_exec(&method)
        end

        accum << scenario
      end
    end

    ##
    # using_scenario applies a scenario to the current context.
    def using_scenario(scenario)
      method = Scenarios.instance_method(scenario)
                        .bind(self)

      instance_exec(&method)
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
    # permits asserts the current bearer and token are permitted to perform
    # the given actions.
    def permits(*actions)
      actions.flatten.each do |action|
        it "should permit #{action}" do
          expect(subject).to permit(action)
        end
      end
    end

    ##
    # forbids asserts the current bearer and token are not permitted to perform
    # the given actions.
    def forbids(*actions)
      actions.flatten.each do |action|
        it "should forbid #{action}" do
          expect(subject).to_not permit(action)
        end
      end
    end
  end

  ##
  # included mixes in ClassMethods on include.
  def self.included(klass)
    klass.extend ClassMethods
  end

  ##
  # authorization_context creates a new authorization context.
  def authorization_context(account:, bearer: nil, token: nil)
    AuthorizationContext.new(account:, bearer:, token:)
  end

  ##
  # authorization_context creates a new authorization resource.
  def authorization_resource(subject:, context: nil)
    AuthorizationResource.new(subject:, context:)
  end
end
