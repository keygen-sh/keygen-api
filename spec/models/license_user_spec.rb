# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe LicenseUser, type: :model do
  let(:account) { create(:account) }

  it_behaves_like :environmental
  it_behaves_like :accountable

  context 'on create' do
    it 'should raise on license and user account mismatch' do
      other_account = create(:account)
      license       = create(:license, account: other_account)
      user          = create(:user, account: other_account)

      expect { create(:license_user, account:, license:, user:) }.to raise_error ActiveRecord::RecordInvalid
    end

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

  context 'on destroy' do
    it "should nilify the user's machines for the license" do
      license      = create(:license, account:)
      user         = create(:user, account:)
      license_user = create(:license_user, account:, license:, user:)
      machine      = create(:machine, account:, license:, owner: user)

      expect { license_user.destroy }.to change { user.machines.count }.by(-1)
        .and not_change { license.machines.count }
      expect(machine.reload.owner).to be nil
    end

    it 'should not nilify other machines for the license' do
      license      = create(:license, account:)
      user         = create(:user, account:)
      license_user = create(:license_user, account:, license:, user:)

      other_machine = create(:machine, :with_owner, account:, license:)

      expect { license_user.destroy }.to_not change { license.machines.count }
      expect(other_machine.reload.owner).to_not be nil
    end

    it "should not nilify machines for the user's other licenses" do
      license      = create(:license, account:)
      user         = create(:user, account:)
      license_user = create(:license_user, account:, license:, user:)

      other_license      = create(:license, account:)
      other_license_user = create(:license_user, account:, license: other_license, user:)
      other_machine      = create(:machine, account:, license: other_license, owner: user)

      expect { license_user.destroy }.to_not change { user.machines.count }
      expect(other_machine.reload.owner).to_not be nil
    end
  end
end
