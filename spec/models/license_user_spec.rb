# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe LicenseUser, type: :model do
  let(:account) { create(:account) }

  it_behaves_like :environmental
  it_behaves_like :accountable

  it 'should raise on license account mismatch' do
    other_account = create(:account)
    license       = create(:license, account: other_account)
    user          = create(:user, account:)

    expect { create(:license_user, account:, license:, user:) }.to raise_error ActiveRecord::RecordInvalid
  end

  it 'should raise on user account mismatch' do
    other_account = create(:account)
    license       = create(:license, account:)
    user          = create(:user, account: other_account)

    expect { create(:license_user, account:, license:, user:) }.to raise_error ActiveRecord::RecordInvalid
  end

  it 'should raise on duplicate' do
    license = create(:license, account:)
    user    = create(:user, account:)

    expect { create(:license_user, account:, license:, user:) }.to_not raise_error
    expect { create(:license_user, account:, license:, user:) }.to raise_error ActiveRecord::RecordInvalid
  end

  it 'should not raise' do
    license = create(:license, account:)
    user    = create(:user, account:)

    expect { create(:license_user, account:, license:, user:) }.to_not raise_error
  end
end
