# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Environment, type: :model do
  let(:account) { create(:account) }

  it_behaves_like :accountable

  %i[isolated shared].each do |isolation|
    it "should promote nested #{isolation} users to admins on create" do
      users_attributes = [
        attributes_for(:user, account:),
        attributes_for(:user, account:),
        attributes_for(:user, account:),
      ]

      # We also want to make sure existing users in the nil environment are not promoted
      create_list(:user, 3,
        account:,
      )

      environment = build(:environment, isolation,
        users_attributes:,
        account:,
      )

      expect { environment.save }.to change { account.admins.count }
    end

    it "should not promote #{isolation} users to admins on create" do
      environment = build(:environment, isolation, account:)
      users       = build_list(:user, 3, account:, environment:)

      create_list(:user, 3,
        account:,
      )

      expect { environment.save }.to_not change { account.admins.count }
    end

    it "should not promote #{isolation} users to admins on update" do
      environment = create(:environment, isolation, account:)
      users       = create_list(:user, 3, account:, environment:)

      create_list(:user, 3,
        account:,
      )

      expect { environment.touch }.to_not change { account.admins.count }
    end
  end
end
