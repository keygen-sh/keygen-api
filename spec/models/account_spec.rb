# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Account, type: :model do
  it 'should promote nested users to admins on create' do
    users_attributes = [
      attributes_for(:user, account: nil),
      attributes_for(:user, account: nil),
      attributes_for(:user, account: nil),
    ]

    account = build(:account,
      users_attributes:,
    )

    expect { account.save }.to(
      # Since the new account will have 1 admin automatically, we're expecting >= 3.
      change { account.admins.count }.by_at_least(3),
    )
  end

  it 'should not promote users to admins on create' do
    account = build(:account)
    users   = build_list(:user, 3, account:)

    expect { account.save }.to(
      # Since the new account will have 1 admin automatically, we're expecting <= 1.
      change { account.admins.count }.by_at_most(1),
    )
  end

  it 'should not promote users to admins on update' do
    account = create(:account)
    users   = create_list(:user, 3, account:)

    expect { account.touch }.to_not change { account.admins.count }
  end
end
