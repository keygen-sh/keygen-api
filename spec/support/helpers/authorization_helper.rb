# frozen_string_literal: true

module AuthorizationHelper
  ##
  # Scenarios contains predefined scenarios to keep spec files clean and
  # easy to write, for security's sake.
  module Scenarios
    def as_admin_accessing_product
      let(:account)  { create(:account) }
      let(:bearer)   { create(:admin, account:, permissions:) }
      let(:resource) { create(:product, account:) }
    end

    def as_product_accessing_itself
      let(:account)  { create(:account) }
      let(:bearer)   { create(:product, account:, permissions:) }
      let(:resource) { bearer }
    end

    def as_product_accessing_another_product
      let(:account)  { create(:account) }
      let(:bearer)   { create(:product, account:, permissions:) }
      let(:resource) { create(:product, account:) }
    end

    def as_license_accessing_product
      let(:account)  { create(:account) }
      let(:bearer)   { create(:license, account:, permissions:) }
      let(:resource) { product }
      let(:policy)   { create(:policy, account:, product:) }
      let(:product)  { create(:product, account:) }
    end

    def as_license_accessing_another_product
      let(:account)  { create(:account) }
      let(:bearer)   { create(:license, account:, permissions:) }
      let(:resource) { create(:product, account:) }
      let(:policy)   { create(:policy, account:, product:) }
      let(:product)  { create(:product, account:) }
    end

    def as_licensed_user_accessing_product
      let(:account)  { create(:account) }
      let(:bearer)   { create(:user, account:, licenses:, permissions:) }
      let(:resource) { product }
      let(:policy)   { create(:policy, account:, product:) }
      let(:product)  { create(:product, account:) }
      let(:licenses) { [create(:license, account:, policy:)] }
    end

    def as_licensed_user_accessing_another_product
      let(:account)  { create(:account) }
      let(:bearer)   { create(:user, account:, licenses:, permissions:) }
      let(:resource) { create(:product, account:) }
      let(:licenses) { [create(:license, account:)] }
    end

    def as_licensed_user_with_multiple_licenses_accessing_product
      let(:account)  { create(:account) }
      let(:bearer)   { create(:user, account:, licenses:, permissions:) }
      let(:resource) { product }
      let(:policy)   { create(:policy, account:, product:) }
      let(:product)  { create(:product, account:) }
      let(:licenses) {
        [
          create(:license, account:, policy:),
          create(:license, account:),
          create(:license, account:),
        ]
      }
    end

    def as_unlicensed_user_accessing_product
      let(:account)  { create(:account) }
      let(:bearer)   { create(:user, account:, permissions:) }
      let(:resource) { create(:product, account:) }
    end

    def as_anonymous_accessing_product
      let(:account)  { create(:account) }
      let(:resource) { create(:product, account:) }
    end
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
    # with_scenario applies a scenario to a new context.
    def with_scenario(scenario, &block)
      context "using #{scenario} scenario" do
        method = Scenarios.instance_method(scenario)
                          .bind(self)

        instance_exec(&method)
        instance_exec(&block)
      end
    end

    ##
    # with_scenario applies a scenario to the current context.
    def using_scenario(scenario)
      method = Scenarios.instance_method(scenario)
                        .bind(self)

      instance_exec(&method)
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
