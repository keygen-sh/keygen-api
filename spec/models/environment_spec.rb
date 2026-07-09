# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Environment, :only_ee, type: :model do
  let(:account) { create(:account) }

  it_behaves_like :accountable

  context 'with an isolated isolation strategy' do
    it 'should promote nested isolated users to admins on create' do
      users_attributes = [
        attributes_for(:user, account:),
        attributes_for(:user, account:),
        attributes_for(:user, account:),
      ]

      # We also want to make sure existing users in the nil environment are not promoted
      create_list(:user, 3,
        account:,
      )

      environment = build(:environment, :isolated,
        users_attributes:,
        account:,
      )

      expect { environment.save }.to change { account.admins.count }
    end

    it 'should not promote isolated users to admins on create' do
      environment = build(:environment, :isolated, account:)
      users       = build_list(:user, 3, account:, environment:)

      create_list(:user, 3,
        account:,
      )

      expect { environment.save }.to_not change { account.admins.count }
    end

    it 'should not promote isolated users to admins on update' do
      environment = create(:environment, :isolated, account:)
      users       = create_list(:user, 3, account:, environment:)

      create_list(:user, 3,
        account:,
      )

      expect { environment.touch }.to_not change { account.admins.count }
    end
  end

  context 'with a shared isolation strategy' do
    it 'should promote nested shared users to admins on create' do
      users_attributes = [
        attributes_for(:user, account:),
        attributes_for(:user, account:),
        attributes_for(:user, account:),
      ]

      # We also want to make sure existing users in the nil environment are not promoted
      create_list(:user, 3,
        account:,
      )

      environment = build(:environment, :shared,
        users_attributes:,
        account:,
      )

      expect { environment.save }.to change { account.admins.count }
    end

    it 'should not promote shared users to admins on create' do
      environment = build(:environment, :shared, account:)
      users       = build_list(:user, 3, account:, environment:)

      create_list(:user, 3,
        account:,
      )

      expect { environment.save }.to_not change { account.admins.count }
    end

    it 'should not promote shared users to admins on update' do
      environment = create(:environment, :shared, account:)
      users       = create_list(:user, 3, account:, environment:)

      create_list(:user, 3,
        account:,
      )

      expect { environment.touch }.to_not change { account.admins.count }
    end
  end

  # Environment#tokens is scoped to the environment under :environment_id,
  # not to the environment under :bearer_id, i.e. it contains tokens borne
  # by other bearers within the environment. without an explicit :inverse_of,
  # which we have, the ownership check would resolve the relation's inverse,
  # i.e. Token#environment, matching every token in the environment.
  describe 'when denormalizing role to tokens' do
    let(:environment) { create(:environment, account:) }
    let(:user)        { create(:user, account:, environment:) }

    context 'on initialization' do
      it 'should only write to loaded records owned by the :through record' do
        environment_token = create(:token, account:, bearer: environment)
        user_token        = create(:token, account:, bearer: user, environment:)

        tokens = environment.tokens.load # preload

        build(:role, account:, resource: environment, name: 'renamed')

        expect(tokens.find { it.id == environment_token.id }.bearer_role).to eq 'renamed'
        expect(tokens.find { it.id == user_token.id }.bearer_role).to eq 'user'
      end
    end

    context 'on create' do
      before { Sidekiq::Testing.inline! }
      after  { Sidekiq::Testing.fake! }

      it 'should update records owned by the :through record' do
        environment_token = create(:token, account:, bearer: environment)
        user_token        = create(:token, account:, bearer: user, environment:)

        environment.role.delete # clear prior role since role asserts uniqueness

        role = build(:role, account:, resource: environment, name: 'renamed')

        # NB(ezekg) role names are validated by resource type, so we need to
        #           bypass validations to exercise a rename
        role.save!(validate: false)

        tokens = environment.tokens.load

        expect(tokens.find { it.id == environment_token.id }.bearer_role).to eq 'renamed'
        expect(tokens.find { it.id == user_token.id }.bearer_role).to eq 'user'
      end
    end

    context 'on update' do
      before { Sidekiq::Testing.inline! }
      after  { Sidekiq::Testing.fake! }

      it 'should only update records owned by the :through record' do
        environment_token = create(:token, account:, bearer: environment)
        user_token        = create(:token, account:, bearer: user, environment:)

        # NB(ezekg) role names are validated by resource type, so we need to
        #           bypass validations to exercise a rename
        environment.role.update_attribute(:name, 'renamed')

        expect(environment_token.reload.bearer_role).to eq 'renamed'
        expect(user_token.reload.bearer_role).to eq 'user'
      end
    end
  end
end
