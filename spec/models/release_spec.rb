# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Release, type: :model do
  let(:account)  { create(:account) }
  let(:product)  { create(:product, account:) }
  let(:accessor) { create(:admin, account:) }

  it_behaves_like :environmental
  it_behaves_like :accountable

  describe '#environment=', only: :ee do
    context 'on create' do
      it 'should apply default environment matching product' do
        environment = create(:environment, account:)
        product     = create(:product, account:, environment:)
        release     = create(:release, account:, product:)

        expect(release.environment).to eq product.environment
      end

      it 'should not raise when environment matches product' do
        environment = create(:environment, account:)
        product     = create(:product, account:, environment:)

        expect { create(:release, account:, environment:, product:) }.to_not raise_error
      end

      it 'should raise when environment does not match product' do
        environment = create(:environment, account:)
        product     = create(:product, account:, environment: nil)

        expect { create(:release, account:, environment:, product:) }.to raise_error ActiveRecord::RecordInvalid
      end

      it 'should not raise when environment matches package' do
        environment = create(:environment, account:)
        product     = create(:product, account:, environment:)
        package     = create(:package, account:, product:, environment:)

        expect { create(:release, account:, environment:, product:, package:) }.to_not raise_error
      end

      it 'should raise when environment does not match package' do
        environment = create(:environment, account:)
        product     = create(:product, account:, environment:)
        package     = create(:package, account:, product:)

        # We can't really get here with all of the package's validations
        package.environment = nil

        expect { create(:release, account:, environment:, package:, product:) }.to raise_error ActiveRecord::RecordInvalid
      end
    end

    context 'on update' do
      it 'should not raise when environment matches product' do
        environment = create(:environment, account:)
        release     = create(:release, account:, environment:)

        expect { release.update!(product: create(:product, account:, environment:)) }.to_not raise_error
      end

      it 'should raise when environment does not match product' do
        environment = create(:environment, account:)
        release     = create(:release, account:, environment:)

        expect { release.update!(product: create(:product, account:, environment: nil)) }.to raise_error ActiveRecord::RecordInvalid
      end

      it 'should not raise when environment matches package' do
        environment = create(:environment, account:)
        product     = create(:product, account:, environment:)
        release     = create(:release, account:, product:, environment:)
        package     = create(:package, account:, product:, environment:)

        expect { release.update!(package:) }.to_not raise_error
      end

      it 'should raise when environment does not match package' do
        environment = create(:environment, account:)
        product     = create(:product, account:, environment:)
        release     = create(:release, account:, product:, environment:)
        package     = create(:package, account:, product:)

        # We can't really get here with all of the package's validations
        package.environment = nil

        expect { release.update!(package:) }.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end

  describe '#constraints_attributes=' do
    it 'should not raise when constraint is valid' do
      release = build(:release, account:, constraints_attributes: [
        attributes_for(:constraint, account:, environment: nil),
      ])

      expect { release.save! }.to_not raise_error
    end

    it 'should raise when constraint is duplicated' do
      entitlement = create(:entitlement, account:)
      release     = build(:release, account:, constraints_attributes: [
        attributes_for(:constraint, account:, entitlement:, environment: nil),
        attributes_for(:constraint, account:, entitlement:, environment: nil),
      ])

      expect { release.save! }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'should raise when constraint is invalid' do
      release = build(:release, account:, constraints_attributes: [
        attributes_for(:constraint, account:, entitlement: nil, environment: nil),
        attributes_for(:constraint, account:, environment: nil),
      ])

      expect { release.save! }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  describe '#constraints=' do
    it 'should not raise when constraint is valid' do
      release = build(:release, account:, constraints: build_list(:constraint, 3, account:))

      expect { release.save! }.to_not raise_error
    end

    it 'should raise when constraint is duplicated' do
      entitlement = create(:entitlement, account:)
      release     = build(:release, account:, constraints: build_list(:constraint, 3, account:, entitlement:))

      expect { release.save! }.to raise_error ActiveRecord::RecordNotUnique
    end

    it 'should raise when constraint is invalid' do
      release = build(:release, account:, constraints: build_list(:constraint, 3, account:, entitlement: nil))

      expect { release.save! }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  describe '#package=' do
    context 'on create' do
      it 'should not raise when package product matches product' do
        product = create(:product, account:)
        package = create(:package, account:, product:)

        expect { create(:release, account:, product:, package:) }.to_not raise_error
      end

      it 'should raise when package product does not match product' do
        package = create(:package, account:)

        expect { create(:release, account:, package:) }.to raise_error ActiveRecord::RecordInvalid
      end
    end

    context 'on update' do
      it 'should not raise when package product matches product' do
        product = create(:product, account:)
        release = create(:release, :packaged, account:, product:)
        package = create(:package, account:, product:)

        expect { release.update!(package:) }.to_not raise_error
      end

      it 'should raise when package product does not match product' do
        release = create(:release, :packaged, account:)
        package = create(:package, account:)

        expect { release.update!(package:) }.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end

  describe '#channel=' do
    context 'channel does not exist' do
      it 'should create channel' do
        expect { create(:release, :beta, account:) }.to change { account.release_channels.count }
      end
    end

    context 'channel does exist' do
      before { create(:channel, :beta, account:) }

      it 'should not create channel' do
        expect { create(:release, :beta, account:) }.to_not change { account.release_channels.count }
      end
    end
  end

  describe '.without_constraints' do
    let(:releases) { described_class.where(account:) }

    before do
      create(:release, constraints: [build(:constraint, account:)], product:, account:)
      create(:release, product:, account:)
    end

    it 'should filter releases without constraints' do
      expect(releases.without_constraints.ids).to match_array [releases.second.id]
    end
  end

  describe '.with_constraints' do
    let(:releases) { described_class.where(account:) }

    before do
      create(:release, constraints: [build(:constraint, account:)], product:, account:)
      create(:release, product:, account:)
    end

    it 'should filter releases with constraints' do
      expect(releases.with_constraints.ids).to match_array [releases.first.id]
    end
  end

  describe '.within_constraints' do
    let(:releases) { described_class.where(account:) }

    before do
      e0 = create(:entitlement, code: 'A', account:)
      e1 = create(:entitlement, code: 'B', account:)
      e2 = create(:entitlement, code: 'C', account:)
      e3 = create(:entitlement, code: 'D', account:)
      e4 = create(:entitlement, code: 'E', account:)

      create(:release, constraints: [build(:constraint, entitlement: e0, account:), build(:constraint, entitlement: e1, account:), build(:constraint, entitlement: e2, account:), build(:constraint, entitlement: e3, account:)], product:, account:)
      create(:release, constraints: [build(:constraint, entitlement: e0, account:), build(:constraint, entitlement: e1, account:), build(:constraint, entitlement: e2, account:)], product:, account:)
      create(:release, constraints: [build(:constraint, entitlement: e0, account:), build(:constraint, entitlement: e2, account:)], product:, account:)
      create(:release, constraints: [build(:constraint, entitlement: e0, account:)], product:, account:)
      create(:release, product:, account:)
      create(:release, constraints: [build(:constraint, entitlement: e4, account:)], product:, account:)
    end

    context 'strict mode disabled' do
      it 'should filter releases within constraints' do
        expect(releases.within_constraints('A', 'B', 'C', strict: false).ids).to match_array [
          releases.first.id,
          releases.second.id,
          releases.third.id,
          releases.fourth.id,
          releases.fifth.id,
        ]
      end
    end

    context 'strict mode enabled' do
      it 'should filter releases within constraints' do
        expect(releases.within_constraints('A', 'B', 'C', strict: true).ids).to match_array [
          releases.second.id,
          releases.third.id,
          releases.fourth.id,
          releases.fifth.id,
        ]
      end
    end

    it 'should filter releases with constraints' do
      expect(releases.within_constraints.ids).to match_array [
        releases.fifth.id,
      ]
    end
  end

  describe '#semver' do
    it 'should normalize its version' do
      release = create(:release, :published, version: '2', product:, account:)

      expect(release.version).to eq '2.0.0'
    end

    it 'should persist its semver components' do
      release = create(:release, :published, version: '1.2.3', product:, account:)

      expect(release.semver_major).to eq 1
      expect(release.semver_minor).to eq 2
      expect(release.semver_patch).to eq 3
    end

    it 'should persist its semver prerelease tag' do
      release = create(:release, :published, version: '1.0.0-alpha.1', product:, account:)

      expect(release.semver_pre_word).to eq 'alpha'
      expect(release.semver_pre_num).to eq 1
    end

    it 'should persist its semver build metadata' do
      release = create(:release, :published, version: '1.0.0+build.12345f', product:, account:)

      expect(release.semver_build_word).to eq 'build.12345f'
      expect(release.semver_build_num).to eq nil
    end
  end

  describe '#upgrade!' do
    context 'when there are no other releases' do
      subject { create(:release, :published, product:, account:) }

      it 'should not upgrade' do
        expect { subject.upgrade!(accessor:) }.to raise_error Keygen::Error::NotFoundError
      end
    end

    context 'when there is no upgrade available' do
      subject { create(:release, :published, version: '2.0.1', product:, account:) }

      before do
        versions = %w[
          1.0.0-beta
          1.0.0-beta.2
          1.0.0-beta+exp.sha.6
          1.0.0-alpha.beta
          1.0.0+20130313144700
          1.0.0-alpha
          1.0.0-beta.11
          1.0.0-alpha.1
          1.0.0
          1.0.0+21AF26D3
          1.0.0-beta+exp.sha.5114f85
          1.0.0-rc.1
          1.0.0-alpha+001
          1.0.1
          1.1.3
          1.9.42
          2.0.0
          2.0.0-alpha.1
          2.0.0-alpha.2
          2.0.0-alpha.3
          2.0.0-beta.1
          2.0.0-rc.1
          2.1.0-beta.1
          2.1.0-rc.1
        ]

        versions.each { create(:release, :published, version: it, product:, account:) }
      end

      it 'should not upgrade' do
        expect { subject.upgrade!(accessor:) }.to raise_error Keygen::Error::NotFoundError
      end
    end

    context 'when there is a draft upgrade available' do
      subject { create(:release, :published, version: '1.0.0', product:, account:) }

       before do
        create(:release, :draft, version: '2.0.0', product:, account:)
      end

      it 'should not upgrade' do
        expect { subject.upgrade!(accessor:) }.to raise_error Keygen::Error::NotFoundError
      end
    end

    context 'when there is a yanked upgrade available' do
      subject { create(:release, :published, version: '1.0.0', product:, account:) }

       before do
        create(:release, :yanked, version: '2.0.0', product:, account:)
      end

      it 'should not upgrade' do
        expect { subject.upgrade!(accessor:) }.to raise_error Keygen::Error::NotFoundError
      end
    end

    context 'when there is a an upgrade available' do
      before do
        versions = %w[
          1.0.0-beta
          1.0.0-beta.2
          1.0.0-beta+exp.sha.6
          1.1.0-alpha.beta
          1.1.0+20130313144700
          1.1.0-alpha
          1.1.0-beta.11
          1.1.0-alpha.1
          1.1.0
          1.1.0+21AF26D3
          1.1.0-beta+exp.sha.5114f85
          1.1.0-rc.1
          1.1.0-alpha+001
          1.1.1
          1.1.3
          1.1.21
          2.0.1
          2.0.2
          2.1.0
          2.1.2-alpha.1
          2.1.9-rc.1
          2.1.9
          2.9.0
          2.11.0-beta.1
          3.0.0
          3.0.2
        ]

        versions.each { create(:release, :published, version: it, product:, account:) }
      end

      context 'when upgrading from the stable channel' do
        subject { create(:release, :published, version: '3.0.1', product:, account:) }

        context 'when the upgrade is for the stable channel' do
          before { create(:release, :published, version: '3.1.0', product:, account:) }

          it 'should upgrade to the latest version' do
            upgrade = subject.upgrade!(accessor:)
            assert upgrade

            expect(upgrade.version).to eq '3.1.0'
          end
        end

        context 'when the upgrade is for the rc channel' do
          before { create(:release, :published, version: '3.1.0-rc.1', product:, account:) }

          it 'should not upgrade to the rc release' do
            upgrade = subject.upgrade!(accessor:)
            assert upgrade

            expect(upgrade.version).to eq '3.0.2'
          end

          it 'should upgrade with explicit rc channel' do
            upgrade = subject.upgrade!(accessor:, channel: 'rc')
            assert upgrade

            expect(upgrade.version).to eq '3.1.0-rc.1'
          end
        end

        context 'when the upgrade is for the beta channel' do
          before { create(:release, :published, version: '3.1.0-beta.1', product:, account:) }

          it 'should not upgrade to the beta release' do
            upgrade = subject.upgrade!(accessor:)
            assert upgrade

            expect(upgrade.version).to eq '3.0.2'
          end

          it 'should upgrade with explicit beta channel' do
            upgrade = subject.upgrade!(accessor:, channel: 'beta')
            assert upgrade

            expect(upgrade.version).to eq '3.1.0-beta.1'
          end
        end

        context 'when the upgrade is for the alpha channel' do
          before { create(:release, :published, version: '3.1.0-alpha.1', product:, account:) }

          it 'should not upgrade to the alpha release' do
            upgrade = subject.upgrade!(accessor:)
            assert upgrade

            expect(upgrade.version).to eq '3.0.2'
          end

          it 'should upgrade with explicit alpha channel' do
            upgrade = subject.upgrade!(accessor:, channel: 'alpha')
            assert upgrade

            expect(upgrade.version).to eq '3.1.0-alpha.1'
          end
        end

        context 'when the upgrade is for the dev channel' do
          before { create(:release, :published, version: '3.1.0-dev.1', product:, account:) }

          it 'should not upgrade to the dev release' do
            upgrade = subject.upgrade!(accessor:)
            assert upgrade

            expect(upgrade.version).to eq '3.0.2'
          end

          it 'should upgrade with explicit dev channel' do
            upgrade = subject.upgrade!(accessor:, channel: 'dev')
            assert upgrade

            expect(upgrade.version).to eq '3.1.0-dev.1'
          end
        end
      end

      context 'when upgrading from the rc channel' do
        subject { create(:release, :published, version: '3.0.1-rc.1', product:, account:) }

        context 'when the upgrade is for the stable channel' do
          before { create(:release, :published, version: '3.1.0', product:, account:) }

          it 'should upgrade to the latest version' do
            upgrade = subject.upgrade!(accessor:)
            assert upgrade

            expect(upgrade.version).to eq '3.1.0'
          end
        end

        context 'when the upgrade is for the rc channel' do
          before { create(:release, :published, version: '3.1.0-rc.1', product:, account:) }

          it 'should upgrade to the rc release' do
            upgrade = subject.upgrade!(accessor:)
            assert upgrade

            expect(upgrade.version).to eq '3.1.0-rc.1'
          end
        end

        context 'when the upgrade is for the beta channel' do
          before { create(:release, :published, version: '3.1.0-beta.1', product:, account:) }

          it 'should not upgrade to the beta release' do
            upgrade = subject.upgrade!(accessor:)
            assert upgrade

            expect(upgrade.version).to eq '3.0.2'
          end
        end

        context 'when the upgrade is for the alpha channel' do
          before { create(:release, :published, version: '3.1.0-alpha.1', product:, account:) }

          it 'should not upgrade to the alpha release' do
            upgrade = subject.upgrade!(accessor:)
            assert upgrade

            expect(upgrade.version).to eq '3.0.2'
          end
        end

        context 'when the upgrade is for the dev channel' do
          before { create(:release, :published, version: '3.1.0-dev.1', product:, account:) }

          it 'should not upgrade to the dev release' do
            upgrade = subject.upgrade!(accessor:)
            assert upgrade

            expect(upgrade.version).to eq '3.0.2'
          end
        end
      end

      context 'when upgrading from the beta channel' do
        subject { create(:release, :published, version: '3.0.1-beta.1', product:, account:) }

        context 'when the upgrade is for the stable channel' do
          before { create(:release, :published, version: '3.1.0', product:, account:) }

          it 'should upgrade to the latest version' do
            upgrade = subject.upgrade!(accessor:)
            assert upgrade

            expect(upgrade.version).to eq '3.1.0'
          end
        end

        context 'when the upgrade is for the rc channel' do
          before { create(:release, :published, version: '3.1.0-rc.1', product:, account:) }

          it 'should upgrade to the rc release' do
            upgrade = subject.upgrade!(accessor:)
            assert upgrade

            expect(upgrade.version).to eq '3.1.0-rc.1'
          end
        end

        context 'when the upgrade is for the beta channel' do
          before { create(:release, :published, version: '3.1.0-beta.1', product:, account:) }

          it 'should upgrade to the beta release' do
            upgrade = subject.upgrade!(accessor:)
            assert upgrade

            expect(upgrade.version).to eq '3.1.0-beta.1'
          end
        end

        context 'when the upgrade is for the alpha channel' do
          before { create(:release, :published, version: '3.1.0-alpha.1', product:, account:) }

          it 'should not upgrade to the alpha release' do
            upgrade = subject.upgrade!(accessor:)
            assert upgrade

            expect(upgrade.version).to eq '3.0.2'
          end
        end

        context 'when the upgrade is for the dev channel' do
          before { create(:release, :published, version: '3.1.0-dev.1', product:, account:) }

          it 'should not upgrade to the dev release' do
            upgrade = subject.upgrade!(accessor:)
            assert upgrade

            expect(upgrade.version).to eq '3.0.2'
          end
        end
      end

      context 'when upgrading from the alpha channel' do
        subject { create(:release, :published, version: '3.0.3-alpha.1', product:, account:) }

        context 'when the upgrade is for the stable channel' do
          before { create(:release, :published, version: '3.0.3', product:, account:) }

          it 'should upgrade to the latest version' do
            upgrade = subject.upgrade!(accessor:)
            assert upgrade

            expect(upgrade.version).to eq '3.0.3'
          end
        end

        context 'when the upgrade is for the rc channel' do
          before { create(:release, :published, version: '3.1.0-rc.1', product:, account:) }

          it 'should upgrade to the rc release' do
            upgrade = subject.upgrade!(accessor:)
            assert upgrade

            expect(upgrade.version).to eq '3.1.0-rc.1'
          end
        end

        context 'when the upgrade is for the beta channel' do
          before { create(:release, :published, version: '3.1.0-beta.1', product:, account:) }

          it 'should upgrade to the beta release' do
            upgrade = subject.upgrade!(accessor:)
            assert upgrade

            expect(upgrade.version).to eq '3.1.0-beta.1'
          end
        end

        context 'when the upgrade is for the alpha channel' do
          before { create(:release, :published, version: '3.1.0-alpha.1', product:, account:) }

          it 'should upgrade to the alpha release' do
            upgrade = subject.upgrade!(accessor:)
            assert upgrade

            expect(upgrade.version).to eq '3.1.0-alpha.1'
          end
        end

        context 'when the upgrade is for the dev channel' do
          before do
            create(:release, :published, version: '3.1.0-dev.1', product:, account:)
            create(:release, :published, version: '3.0.3', product:, account:)
          end

          it 'should not upgrade to the dev release' do
            upgrade = subject.upgrade!(accessor:)
            assert upgrade

            expect(upgrade.version).to eq '3.0.3'
          end
        end
      end

      context 'when upgrading from the dev channel' do
        subject { create(:release, :published, version: '3.0.1-dev.1', product:, account:) }

        context 'when the upgrade is for the stable channel' do
          before { create(:release, :published, version: '3.1.0', product:, account:) }

          it 'should not upgrade to the latest version' do
            expect { subject.upgrade!(accessor:) }.to raise_error Keygen::Error::NotFoundError
          end
        end

        context 'when the upgrade is for the rc channel' do
          before { create(:release, :published, version: '3.1.0-rc.1', product:, account:) }

          it 'should not upgrade to the rc release' do
            expect { subject.upgrade!(accessor:) }.to raise_error Keygen::Error::NotFoundError
          end
        end

        context 'when the upgrade is for the beta channel' do
          before { create(:release, :published, version: '3.1.0-beta.1', product:, account:) }

          it 'should not upgrade to the beta release' do
            expect { subject.upgrade!(accessor:) }.to raise_error Keygen::Error::NotFoundError
          end
        end

        context 'when the upgrade is for the alpha channel' do
          before { create(:release, :published, version: '3.1.0-alpha.1', product:, account:) }

          it 'should not upgrade to the alpha release' do
            expect { subject.upgrade!(accessor:) }.to raise_error Keygen::Error::NotFoundError
          end
        end

        context 'when the upgrade is for the dev channel' do
          before { create(:release, :published, version: '3.1.0-dev.1', product:, account:) }

          it 'should upgrade to the dev release' do
            upgrade = subject.upgrade!(accessor:)
            assert upgrade

            expect(upgrade.version).to eq '3.1.0-dev.1'
          end
        end
      end

      context 'when using a constraint' do
        subject { create(:release, :published, version: '2.0.0', product:, account:) }

        it 'should raise for an invalid constraint' do
          expect { subject.upgrade!(accessor:, constraint: 'invalid') }.to raise_error Semverse::InvalidConstraintFormat
        end

        it 'should upgrade to the latest v2 version' do
          upgrade = subject.upgrade!(accessor:, constraint: '2')
          assert upgrade

          expect(upgrade.version).to eq '2.9.0'
        end

        it 'should upgrade to the latest v2.x version' do
          upgrade = subject.upgrade!(accessor:, constraint: '2.0')
          assert upgrade

          expect(upgrade.version).to eq '2.9.0'
        end

        it 'should upgrade to the latest v2.0.x version' do
          upgrade = subject.upgrade!(accessor:, constraint: '2.1.0')
          assert upgrade

          expect(upgrade.version).to eq '2.1.9'
        end
      end
    end

    context 'when using API version v1.0' do
      subject { create(:release, :published, version: '1.0.0', api_version: '1.0', product:, account:) }

      before do
        5.times { create(:release, :published, version: '1.0.0', api_version: '1.0', product:, account:) }
      end

      it 'should not upgrade to the same version' do
        expect { subject.upgrade!(accessor:) }.to raise_error Keygen::Error::NotFoundError
      end
    end

    context 'when :accessor is a user with an expired license' do
      subject { create(:release, :published, created_at: 1.year.ago, version: '1.0.0', product:, account:) }

      let(:policy) { create(:policy, product:, account:) }
      let(:user)   { create(:user, account:) }

      before do
        create(:release, :published, created_at: 9.months.ago, version: '2.0.0', product:, account:)
        create(:release, :published, created_at: 1.month.ago, version: '3.0.0', product:, account:)
        create(:release, :published, created_at: 1.week.ago, version: '3.0.1', product:, account:)
        create(:release, :published, created_at: 4.days.ago, version: '3.0.2', product:, account:)
        create(:release, :published, created_at: 4.days.ago, version: '3.1.0', product:, account:)
        create(:release, :yanked, created_at: 4.days.ago, version: '3.1.1', product:, account:)
        create(:release, :published, created_at: 1.day.ago, version: '3.1.2', product:, account:)
        create(:release, :draft, created_at: 1.hour.ago, version: '3.1.3', product:, account:)

        create(:license, expiry: 3.days.ago, owner: user, policy:, account:)
      end

      it 'should scope to accessible releases' do
        upgrade = subject.upgrade!(accessor: user)
        assert upgrade

        expect(upgrade.version).to eq '3.1.0'
      end
    end

    context 'when :accessor is an expired license' do
      subject { create(:release, :published, created_at: 1.year.ago, version: '1.0.0', product:, account:) }

      let(:policy)  { create(:policy, product:, account:) }
      let(:license) { create(:license, expiry: 3.days.ago, policy:, account:) }

      before do
        create(:release, :published, created_at: 9.months.ago, version: '2.0.0', product:, account:)
        create(:release, :published, created_at: 1.month.ago, version: '3.0.0', product:, account:)
        create(:release, :published, created_at: 1.week.ago, version: '3.0.1', product:, account:)
        create(:release, :published, created_at: 4.days.ago, version: '3.0.2', product:, account:)
        create(:release, :published, created_at: 4.days.ago, version: '3.1.0', product:, account:)
        create(:release, :yanked, created_at: 4.days.ago, version: '3.1.1', product:, account:)
        create(:release, :published, created_at: 1.day.ago, version: '3.1.2', product:, account:)
        create(:release, :draft, created_at: 1.hour.ago, version: '3.1.3', product:, account:)
      end

      it 'should scope to accessible releases' do
        upgrade = subject.upgrade!(accessor: license)
        assert upgrade

        expect(upgrade.version).to eq '3.1.0'
      end
    end
  end

  describe '#upgrade' do
    context 'when there is no upgrade available' do
      subject { create(:release, :published, version: '2.0.1', product:, account:) }

      before do
        versions = %w[
          1.0.0-beta
          1.0.0-beta.2
          1.0.0-beta+exp.sha.6
          1.0.0-alpha.beta
          1.0.0+20130313144700
          1.0.0-alpha
          1.0.0-beta.11
          1.0.0-alpha.1
          1.0.0
          1.0.0+21AF26D3
          1.0.0-beta+exp.sha.5114f85
          1.0.0-rc.1
          1.0.0-alpha+001
          1.0.1
          1.1.3
          1.9.42
          2.0.0
          2.0.0-alpha.1
          2.0.0-alpha.2
          2.0.0-alpha.3
          2.0.0-beta.1
          2.0.0-rc.1
          2.1.0-beta.1
          2.1.0-rc.1
        ]

        versions.each { create(:release, :published, version: it, product:, account:) }
      end

      it 'should not upgrade' do
        upgrade = subject.upgrade(accessor:)

        expect(upgrade).to be_nil
      end
    end

    context 'when there is a an upgrade available' do
      subject { create(:release, :published, version: '2.0.1', product:, account:) }

      before do
        versions = %w[
          1.0.0-beta
          1.0.0-beta.2
          1.0.0-beta+exp.sha.6
          1.1.0-alpha.beta
          1.1.0+20130313144700
          1.1.0-alpha
          1.1.0-beta.11
          1.1.0-alpha.1
          1.1.0
          1.1.0+21AF26D3
          1.1.0-beta+exp.sha.5114f85
          1.1.0-rc.1
          1.1.0-alpha+001
          1.1.1
          1.1.3
          1.1.21
          2.0.0
          2.0.2
          2.1.0
          2.1.2-alpha.1
          2.1.9-rc.1
          2.1.9
          2.9.0
          2.11.0-beta.1
          3.0.0
          3.0.2
        ]

        versions.each { create(:release, :published, version: it, product:, account:) }
      end

      it 'should upgrade' do
        upgrade = subject.upgrade(accessor:)
        assert upgrade

        expect(upgrade.version).to eq '3.0.2'
      end
    end
  end

  describe '#version=' do
    let(:package) { create(:package, product:, account:) }

    context 'when the version does not exist for the product' do
      it 'should create a release' do
        expect { create(:release, version: '1.0.0', product:, account:) }.to_not raise_error
      end
    end

    context 'when the version does exist for the product' do
      before do
        create(:release, version: '1.0.0', product:, account:)
      end

      it 'should not create a release' do
        expect { create(:release, version: '1.0.0', product:, account:) }.to raise_error ActiveRecord::RecordInvalid
      end
    end

    context 'when the version does not exist for the product or package' do
      it 'should create a release' do
        expect { create(:release, version: '1.0.0', package:, product:, account:) }.to_not raise_error
      end
    end

    context 'when the version does exist for the product but not the package' do
      before do
        create(:release, version: '1.0.0', product:, account:)
      end

      it 'should create a release' do
        expect { create(:release, version: '1.0.0', package:, product:, account:) }.to_not raise_error
      end
    end

    context 'when the version does exist for the package but not the product' do
      before do
        create(:release, version: '1.0.0', package:, product:, account:)
      end

      it 'should create a release' do
        expect { create(:release, version: '1.0.0', product:, account:) }.to_not raise_error
      end
    end

    context 'when the version does exist for the package' do
      before do
        create(:release, version: '1.0.0', package:, product:, account:)
      end

      it 'should not create a release' do
        expect { create(:release, version: '1.0.0', package:, product:, account:) }.to raise_error ActiveRecord::RecordInvalid
      end
    end

    context 'when the version does exist for another product' do
      before do
        create(:release, version: '1.0.0', product: create(:product, account:), account:)
      end

      it 'should create a release' do
        expect { create(:release, version: '1.0.0', product:, account:) }.to_not raise_error
      end
    end

    context 'when the version does exist for another package' do
      before do
        create(:release, version: '1.0.0', package: create(:package, product:, account:), product:, account:)
      end

      it 'should create a release' do
        expect { create(:release, version: '1.0.0', package:, product:, account:) }.to_not raise_error
      end
    end

    context 'when the version does exist for another account' do
      before do
        create(:release, version: '1.0.0', account: create(:account))
      end

      it 'should create a release' do
        expect { create(:release, version: '1.0.0', package:, product:, account:) }.to_not raise_error
      end
    end
  end

  describe '#tag=' do
    let(:package) { create(:package, product:, account:) }

    context 'when the tag does not exist for the product' do
      it 'should create a tagged release' do
        expect { create(:release, tag: 'latest', product:, account:) }.to_not raise_error
      end
    end

    context 'when the tag does exist for the product' do
      before do
        create(:release, tag: 'latest', product:, account:)
      end

      it 'should not create a tagged release' do
        expect { create(:release, tag: 'latest', product:, account:) }.to raise_error ActiveRecord::RecordInvalid
      end
    end

    context 'when the tag does not exist for the product or package' do
      it 'should create a tagged release' do
        expect { create(:release, tag: 'latest', package:, product:, account:) }.to_not raise_error
      end
    end

    context 'when the tag does exist for the product but not the package' do
      before do
        create(:release, tag: 'latest', product:, account:)
      end

      it 'should create a tagged release' do
        expect { create(:release, tag: 'latest', package:, product:, account:) }.to_not raise_error
      end
    end

    context 'when the tag does exist for the package but not the product' do
      before do
        create(:release, tag: 'latest', package:, product:, account:)
      end

      it 'should create a tagged release' do
        expect { create(:release, tag: 'latest', product:, account:) }.to_not raise_error
      end
    end

    context 'when the tag does exist for the package' do
      before do
        create(:release, tag: 'latest', package:, product:, account:)
      end

      it 'should not create a tagged release' do
        expect { create(:release, tag: 'latest', package:, product:, account:) }.to raise_error ActiveRecord::RecordInvalid
      end
    end

    context 'when the tag does exist for another product' do
      before do
        create(:release, tag: 'latest', product: create(:product, account:), account:)
      end

      it 'should create a tagged release' do
        expect { create(:release, tag: 'latest', product:, account:) }.to_not raise_error
      end
    end

    context 'when the tag does exist for another package' do
      before do
        create(:release, tag: 'latest', package: create(:package, product:, account:), product:, account:)
      end

      it 'should create a tagged release' do
        expect { create(:release, tag: 'latest', package:, product:, account:) }.to_not raise_error
      end
    end

    context 'when the tag does exist for another account' do
      before do
        create(:release, tag: 'latest', account: create(:account))
      end

      it 'should create a tagged release' do
        expect { create(:release, tag: 'latest', package:, product:, account:) }.to_not raise_error
      end
    end
  end

  describe '.order_by_version' do
    before do
      versions = %w[
        1.0.0-beta
        1.0.0-beta.2
        1.0.0-beta+exp.sha.6
        1.0.0-alpha.beta
        99.99.99
        1.0.0+20130313144700
        1.0.0-alpha
        1.0.11
        1.0.0-beta.11
        1.0.0-alpha.1
        1.0.0
        69.420.42
        1.11.0
        1.0.0+21AF26D3
        22.0.1-beta.0
        1.0.0-beta+exp.sha.5114f85
        1.0.0-rc.1
        1.0.0-alpha+001
        101.0.0
        1.0.2
        1.1.3
        11.0.0
        1.1.21
        1.2.0
        1.0.1
        2.0.0
        22.0.1
        22.0.1-beta.1
      ]

      versions.map { create(:release, :published, version: it, product:, account:) }
    end

    it 'should sort by semver' do
      versions = described_class.order_by_version.pluck(:version)

      expect(versions).to eq %w[
        101.0.0
        99.99.99
        69.420.42
        22.0.1
        22.0.1-beta.1
        22.0.1-beta.0
        11.0.0
        2.0.0
        1.11.0
        1.2.0
        1.1.21
        1.1.3
        1.0.11
        1.0.2
        1.0.1
        1.0.0+21AF26D3
        1.0.0+20130313144700
        1.0.0
        1.0.0-rc.1
        1.0.0-beta.11
        1.0.0-beta.2
        1.0.0-beta+exp.sha.5114f85
        1.0.0-beta+exp.sha.6
        1.0.0-beta
        1.0.0-alpha.beta
        1.0.0-alpha.1
        1.0.0-alpha+001
        1.0.0-alpha
      ]
    end

    it 'should sort in desc order' do
      versions = described_class.order_by_version(:desc).pluck(:version)

      expect(versions).to eq %w[
        101.0.0
        99.99.99
        69.420.42
        22.0.1
        22.0.1-beta.1
        22.0.1-beta.0
        11.0.0
        2.0.0
        1.11.0
        1.2.0
        1.1.21
        1.1.3
        1.0.11
        1.0.2
        1.0.1
        1.0.0+21AF26D3
        1.0.0+20130313144700
        1.0.0
        1.0.0-rc.1
        1.0.0-beta.11
        1.0.0-beta.2
        1.0.0-beta+exp.sha.5114f85
        1.0.0-beta+exp.sha.6
        1.0.0-beta
        1.0.0-alpha.beta
        1.0.0-alpha.1
        1.0.0-alpha+001
        1.0.0-alpha
      ]
    end

    it 'should sort in asc order' do
      versions = described_class.order_by_version(:asc).pluck(:version)

      expect(versions).to eq %w[
        1.0.0-alpha
        1.0.0-alpha+001
        1.0.0-alpha.1
        1.0.0-alpha.beta
        1.0.0-beta
        1.0.0-beta+exp.sha.6
        1.0.0-beta+exp.sha.5114f85
        1.0.0-beta.2
        1.0.0-beta.11
        1.0.0-rc.1
        1.0.0
        1.0.0+20130313144700
        1.0.0+21AF26D3
        1.0.1
        1.0.2
        1.0.11
        1.1.3
        1.1.21
        1.2.0
        1.11.0
        2.0.0
        11.0.0
        22.0.1-beta.0
        22.0.1-beta.1
        22.0.1
        69.420.42
        99.99.99
        101.0.0
      ]
    end

    it 'should take latest' do
      release = described_class.order_by_version
                               .take

      expect(release.version).to eq '101.0.0'
    end
  end
end
