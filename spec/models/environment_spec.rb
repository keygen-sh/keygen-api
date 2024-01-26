# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Environment, type: :model do
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

      expect { environment.save }.to change { account.admins.count }.by_at_most(+1) # for isolated admin
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
        attributes_for(:user),
        attributes_for(:user),
        attributes_for(:user),
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
end
