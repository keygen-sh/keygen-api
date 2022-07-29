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
        let(:bearer)  { create(:admin, account:, permissions:) }
      end
    end

    def as_product(scenarios)
      case scenarios
      in []
        let(:account) { create(:account) }
        let(:bearer)  { create(:product, account:, permissions:) }
      end
    end

    def as_license(scenarios)
      case scenarios
      in []
        let(:account) { create(:account) }
        let(:bearer)  { create(:license, account:, permissions:) }
      end
    end

    def as_user(scenarios)
      case scenarios
      in []
        let(:account) { create(:account) }
        let(:bearer)  { create(:user, account:, permissions:) }
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
    alias :with_license :with_licenses

    def accessing_itself(scenarios)
      case scenarios
      in [:as_admin | :as_product | :as_license | :as_user, *]
        let(:resource) { bearer }
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
        let(:resource) { create(:product, account: other_account) }
      else
        let(:resource) { create(:product, account:) }
      end
    end
    alias :accessing_another_product :accessing_a_product

    def accessing_its_product(scenarios)
      case scenarios
      in [:as_license, *]
        let(:resource) { bearer.product }
      in [:as_user, *]
        let(:resource) { licenses.first.product }
      end
    end
    alias :accessing_their_product :accessing_its_product

    def accessing_products(scenarios)
      case scenarios
      in [*, :accessing_another_account, *]
        let(:resource) { [create(:product, account: other_account)] }
      else
        let(:resource) { [create(:product, account:)] }
      end
    end
    alias :accessing_other_products :accessing_products

    def accessing_its_products(scenarios)
      case scenarios
      in [:as_license, *]
        let(:resource) { [bearer.product] }
      in [:as_user, *]
        let(:resource) { licenses.collect(&:product) }
      end
    end
    alias :accessing_their_products :accessing_its_products
  end

  ##
  # ClassMethods contains class methods that are mixed in when
  # the AuthorizationHelper is included.
  module ClassMethods
    ##
    # with_role_authorization starts an authorization test for a given role.
    def with_role_authorization(role, &block)
      context "with #{role} authorization" do
        let(:role)        { role.to_sym }
        let(:permissions) { default_permissions(role:) }
        let(:context)     { authorization_context(account:, bearer:, token:) }

        instance_exec(&block)
      end
    end

    ##
    # without_authorization starts an authorization test for an anon.
    def without_authorization(&block)
      context 'without authorization' do
        let(:context) { authorization_context(account:, bearer:, token:) }

        instance_exec(&block)
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
    def with_scenarios(scenarios, &block)
      context "using #{scenarios} scenarios" do
        using_scenarios(scenarios)
        instance_exec(&block)
      end
    end

    ##
    # with_scenario applies a scenario to a new context.
    def with_scenario(scenario, &block)
      context "using #{scenario} scenario" do
        using_scenario(scenario)
        instance_exec(&block)
      end
    end

    ##
    # with_token_authentication defines a context using token authentication.
    def with_token_authentication(&block)
      context 'with token authentication' do
        let(:token) { create(:token, account:, bearer:) }

        instance_exec(&block)
      end
    end

    ##
    # with_license_authentication defines a context using license authentication.
    def with_license_authentication(&block)
      context 'with license authentication' do
        let(:token) { nil }

        it 'bearer is a license' do
          expect(bearer).to be_a License
        end

        instance_exec(&block)
      end
    end

    ##
    # without_authentication defines a context using no authentication.
    def without_authentication(&block)
      context 'without authentication' do
        let(:bearer) { nil }
        let(:token)  { nil }

        instance_exec(&block)
      end
    end

    ##
    # permits asserts the current bearer and token are permitted to perform
    # the given action.
    def permits(action, permissions: [])
      context 'with default permissions' do
        let(:permissions) { default_permissions(role:) }

        it "should permit #{action}" do
          expect(subject).to permit(action)
        end
      end

      context 'with wildcard permissions' do
        let(:permissions) { [Permission::WILDCARD_PERMISSION] }

        it "should permit #{action}" do
          expect(subject).to permit(action)
        end
      end

      if permissions.any?
        context 'with explicit permissions' do
          let(:permissions) { permissions.to_a }

          it "should permit #{action}" do
            expect(subject).to permit(action)
          end
        end
      end

      context 'without permissions' do
        let(:permissions) { [] }

        it "should deny #{action}" do
          expect(subject).to_not permit(action)
        end
      end
    end

    ##
    # forbids asserts the current bearer and token are not permitted to perform
    # the given action.
    def forbids(action, permissions: [])
      context 'with default permissions' do
        let(:permissions) { default_permissions(role:) }

        it "should forbid #{action}" do
          expect(subject).to_not permit(action)
        end
      end

      context 'with wildcard permissions' do
        let(:permissions) { [Permission::WILDCARD_PERMISSION] }

        it "should forbid #{action}" do
          expect(subject).to_not permit(action)
        end
      end

      if permissions.any?
        context 'with explicit permissions' do
          let(:permissions) { permissions.to_a }

          it "should forbid #{action}" do
            expect(subject).to_not permit(action)
          end
        end
      end

      context 'without permissions' do
        let(:permissions) { [] }

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
  # default_permissions returns a role's default permissions.
  def default_permissions(role:)
    case role.to_sym
    when :product
      Permission::PRODUCT_PERMISSIONS
    when :license
      Permission::LICENSE_PERMISSIONS
    when :admin
      Permission::ADMIN_PERMISSIONS
    when :user
      Permission::USER_PERMISSIONS
    end
  end
end
