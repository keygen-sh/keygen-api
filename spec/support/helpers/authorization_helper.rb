# frozen_string_literal: true

module AuthorizationHelper
  SCENARIOS = {
    as_admin_accessing_product: -> {
      let(:account)  { create(:account) }
      let(:bearer)   { create(:admin, account:, permissions:) }
      let(:resource) { create(:product, account:) }
    },
    as_product_accessing_itself: -> {
      let(:account)  { create(:account) }
      let(:bearer)   { create(:product, account:, permissions:) }
      let(:resource) { bearer }
    },
    as_product_accessing_another_product: -> {
      let(:account)  { create(:account) }
      let(:bearer)   { create(:product, account:, permissions:) }
      let(:resource) { create(:product, account:) }
    },
    as_license_accessing_product: -> {
      let(:account)  { create(:account) }
      let(:bearer)   { create(:license, account:, permissions:) }
      let(:resource) { product }
      let(:policy)   { create(:policy, account:, product:) }
      let(:product)  { create(:product, account:) }
    },
    as_license_accessing_another_product: -> {
      let(:account)  { create(:account) }
      let(:bearer)   { create(:license, account:, permissions:) }
      let(:resource) { create(:product, account:) }
      let(:policy)   { create(:policy, account:, product:) }
      let(:product)  { create(:product, account:) }
    },
    as_licensed_user_accessing_product: -> {
      let(:account)  { create(:account) }
      let(:bearer)   { create(:user, account:, licenses:, permissions:) }
      let(:resource) { product }
      let(:policy)   { create(:policy, account:, product:) }
      let(:product)  { create(:product, account:) }
      let(:licenses) { [create(:license, account:, policy:)] }
    },
    as_licensed_user_accessing_another_product: -> {
      let(:account)  { create(:account) }
      let(:bearer)   { create(:user, account:, licenses:, permissions:) }
      let(:resource) { create(:product, account:) }
      let(:licenses) { [create(:license, account:)] }
    },
    as_licensed_user_with_multiple_licenses_accessing_product: -> {
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
    },
    as_unlicensed_user_accessing_product: -> {
      let(:account)  { create(:account) }
      let(:bearer)   { create(:user, account:, permissions:) }
      let(:resource) { create(:product, account:) }
    },
    as_anonymous_accessing_product: -> {
      let(:account)  { create(:account) }
      let(:resource) { create(:product, account:) }
    },
  }.freeze

  def with_role_authorization(role, &block)
    context "with #{role} authorization" do
      let(:role)        { role.to_sym }
      let(:permissions) { default_permissions_for(role:) }
      let(:context)     { authorization_context(account:, bearer:, token:) }

      instance_exec(&block)
    end
  end

  def without_authorization(&block)
    context 'without authorization' do
      let(:context) { authorization_context(account:, bearer:, token:) }

      instance_exec(&block)
    end
  end

  private

  def with_scenario(scenario, &block)
    env = SCENARIOS.fetch(scenario)

    context "using #{scenario} scenario" do
      instance_exec(&env)
      instance_exec(&block)
    end
  end

  def using_scenario(scenario)
    env = SCENARIOS.fetch(scenario)

    instance_exec(&env)
  end

  def with_token_authentication(&block)
    context 'with token authentication' do
      let(:token) { create(:token, account:, bearer:) }

      instance_exec(&block)
    end
  end

  def with_license_authentication(&block)
    context 'with license authentication' do
      let(:token) { nil }

      it 'bearer is a license' do
        expect(bearer).to be_a License
      end

      instance_exec(&block)
    end
  end

  def without_authentication(&block)
    context 'without authentication' do
      let(:bearer) { nil }
      let(:token)  { nil }

      instance_exec(&block)
    end
  end

  def permits(action, assert_permissions: [])
    context 'with default permissions' do
      let(:permissions) { default_permissions_for(role:) }

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

    if assert_permissions.any?
      context 'with explicit permissions' do
        let(:permissions) { assert_permissions }

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

  def forbids(action, assert_permissions: [])
    context 'with default permissions' do
      let(:permissions) { default_permissions_for(role:) }

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

    if assert_permissions.any?
      context 'with explicit permissions' do
        let(:permissions) { assert_permissions }

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

  def authorization_context(account:, bearer: nil, token: nil)
    AuthorizationContext.new(account:, bearer:, token:)
  end

  def default_permissions_for(role:)
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
