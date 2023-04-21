# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Environment, type: :model do
  let(:account) { create(:account) }

  it 'should promote nested users to admins on create' do
    users_attributes = [
      attributes_for(:user),
      attributes_for(:user),
      attributes_for(:user),
    ]

    environment = build(:environment,
      users_attributes:,
      account:,
    )

    expect { environment.save }.to change { account.admins.count }
  end

  it 'should not promote users to admins on create' do
    environment = build(:environment, account:)
    users       = build_list(:user, 3, account:, environment:)

    expect { environment.save }.to_not change { account.admins.count }
  end

  it 'should not promote users to admins on update' do
    environment = create(:environment, account:)
    users       = create_list(:user, 3, account:, environment:)

    expect { environment.touch }.to_not change { account.admins.count }
  end
end
