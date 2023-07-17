# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Release, type: :model do
  let(:account) { create(:account) }
  let(:product) { create(:product, account:) }

  it_behaves_like :environmental

  describe '#environment=' do
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
        expect { subject.upgrade! }.to raise_error Keygen::Error::NotFoundError
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

        versions.each { create(:release, :published, version: _1, product:, account:) }
      end

      it 'should not upgrade' do
        expect { subject.upgrade! }.to raise_error Keygen::Error::NotFoundError
      end
    end

    context 'when there is a draft upgrade available' do
      subject { create(:release, :published, version: '1.0.0', product:, account:) }

       before do
        create(:release, :draft, version: '2.0.0', product:, account:)
      end

      it 'should not upgrade' do
        expect { subject.upgrade! }.to raise_error Keygen::Error::NotFoundError
      end
    end

    context 'when there is a yanked upgrade available' do
      subject { create(:release, :published, version: '1.0.0', product:, account:) }

       before do
        create(:release, :yanked, version: '2.0.0', product:, account:)
      end

      it 'should not upgrade' do
        expect { subject.upgrade! }.to raise_error Keygen::Error::NotFoundError
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

        versions.each { create(:release, :published, version: _1, product:, account:) }
      end

      context 'when upgrading from the stable channel' do
        subject { create(:release, :published, version: '3.0.1', product:, account:) }

        context 'when the upgrade is for the stable channel' do
          before { create(:release, :published, version: '3.1.0', product:, account:) }

          it 'should upgrade to the latest version' do
            upgrade = subject.upgrade!
            assert upgrade

            expect(upgrade.version).to eq '3.1.0'
          end
        end

        context 'when the upgrade is for the rc channel' do
          before { create(:release, :published, version: '3.1.0-rc.1', product:, account:) }

          it 'should not upgrade to the rc release' do
            upgrade = subject.upgrade!
            assert upgrade

            expect(upgrade.version).to eq '3.0.2'
          end

          it 'should upgrade with explicit rc channel' do
            upgrade = subject.upgrade!(channel: 'rc')
            assert upgrade

            expect(upgrade.version).to eq '3.1.0-rc.1'
          end
        end

        context 'when the upgrade is for the beta channel' do
          before { create(:release, :published, version: '3.1.0-beta.1', product:, account:) }

          it 'should not upgrade to the beta release' do
            upgrade = subject.upgrade!
            assert upgrade

            expect(upgrade.version).to eq '3.0.2'
          end

          it 'should upgrade with explicit beta channel' do
            upgrade = subject.upgrade!(channel: 'beta')
            assert upgrade

            expect(upgrade.version).to eq '3.1.0-beta.1'
          end
        end

        context 'when the upgrade is for the alpha channel' do
          before { create(:release, :published, version: '3.1.0-alpha.1', product:, account:) }

          it 'should not upgrade to the alpha release' do
            upgrade = subject.upgrade!
            assert upgrade

            expect(upgrade.version).to eq '3.0.2'
          end

          it 'should upgrade with explicit alpha channel' do
            upgrade = subject.upgrade!(channel: 'alpha')
            assert upgrade

            expect(upgrade.version).to eq '3.1.0-alpha.1'
          end
        end

        context 'when the upgrade is for the dev channel' do
          before { create(:release, :published, version: '3.1.0-dev.1', product:, account:) }

          it 'should not upgrade to the dev release' do
            upgrade = subject.upgrade!
            assert upgrade

            expect(upgrade.version).to eq '3.0.2'
          end

          it 'should upgrade with explicit dev channel' do
            upgrade = subject.upgrade!(channel: 'dev')
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
            upgrade = subject.upgrade!
            assert upgrade

            expect(upgrade.version).to eq '3.1.0'
          end
        end

        context 'when the upgrade is for the rc channel' do
          before { create(:release, :published, version: '3.1.0-rc.1', product:, account:) }

          it 'should upgrade to the rc release' do
            upgrade = subject.upgrade!
            assert upgrade

            expect(upgrade.version).to eq '3.1.0-rc.1'
          end
        end

        context 'when the upgrade is for the beta channel' do
          before { create(:release, :published, version: '3.1.0-beta.1', product:, account:) }

          it 'should not upgrade to the beta release' do
            upgrade = subject.upgrade!
            assert upgrade

            expect(upgrade.version).to eq '3.0.2'
          end
        end

        context 'when the upgrade is for the alpha channel' do
          before { create(:release, :published, version: '3.1.0-alpha.1', product:, account:) }

          it 'should not upgrade to the alpha release' do
            upgrade = subject.upgrade!
            assert upgrade

            expect(upgrade.version).to eq '3.0.2'
          end
        end

        context 'when the upgrade is for the dev channel' do
          before { create(:release, :published, version: '3.1.0-dev.1', product:, account:) }

          it 'should not upgrade to the dev release' do
            upgrade = subject.upgrade!
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
            upgrade = subject.upgrade!
            assert upgrade

            expect(upgrade.version).to eq '3.1.0'
          end
        end

        context 'when the upgrade is for the rc channel' do
          before { create(:release, :published, version: '3.1.0-rc.1', product:, account:) }

          it 'should upgrade to the rc release' do
            upgrade = subject.upgrade!
            assert upgrade

            expect(upgrade.version).to eq '3.1.0-rc.1'
          end
        end

        context 'when the upgrade is for the beta channel' do
          before { create(:release, :published, version: '3.1.0-beta.1', product:, account:) }

          it 'should upgrade to the beta release' do
            upgrade = subject.upgrade!
            assert upgrade

            expect(upgrade.version).to eq '3.1.0-beta.1'
          end
        end

        context 'when the upgrade is for the alpha channel' do
          before { create(:release, :published, version: '3.1.0-alpha.1', product:, account:) }

          it 'should not upgrade to the alpha release' do
            upgrade = subject.upgrade!
            assert upgrade

            expect(upgrade.version).to eq '3.0.2'
          end
        end

        context 'when the upgrade is for the dev channel' do
          before { create(:release, :published, version: '3.1.0-dev.1', product:, account:) }

          it 'should not upgrade to the dev release' do
            upgrade = subject.upgrade!
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
            upgrade = subject.upgrade!
            assert upgrade

            expect(upgrade.version).to eq '3.0.3'
          end
        end

        context 'when the upgrade is for the rc channel' do
          before { create(:release, :published, version: '3.1.0-rc.1', product:, account:) }

          it 'should upgrade to the rc release' do
            upgrade = subject.upgrade!
            assert upgrade

            expect(upgrade.version).to eq '3.1.0-rc.1'
          end
        end

        context 'when the upgrade is for the beta channel' do
          before { create(:release, :published, version: '3.1.0-beta.1', product:, account:) }

          it 'should upgrade to the beta release' do
            upgrade = subject.upgrade!
            assert upgrade

            expect(upgrade.version).to eq '3.1.0-beta.1'
          end
        end

        context 'when the upgrade is for the alpha channel' do
          before { create(:release, :published, version: '3.1.0-alpha.1', product:, account:) }

          it 'should upgrade to the alpha release' do
            upgrade = subject.upgrade!
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
            upgrade = subject.upgrade!
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
            expect { subject.upgrade! }.to raise_error Keygen::Error::NotFoundError
          end
        end

        context 'when the upgrade is for the rc channel' do
          before { create(:release, :published, version: '3.1.0-rc.1', product:, account:) }

          it 'should not upgrade to the rc release' do
            expect { subject.upgrade! }.to raise_error Keygen::Error::NotFoundError
          end
        end

        context 'when the upgrade is for the beta channel' do
          before { create(:release, :published, version: '3.1.0-beta.1', product:, account:) }

          it 'should not upgrade to the beta release' do
            expect { subject.upgrade! }.to raise_error Keygen::Error::NotFoundError
          end
        end

        context 'when the upgrade is for the alpha channel' do
          before { create(:release, :published, version: '3.1.0-alpha.1', product:, account:) }

          it 'should not upgrade to the alpha release' do
            expect { subject.upgrade! }.to raise_error Keygen::Error::NotFoundError
          end
        end

        context 'when the upgrade is for the dev channel' do
          before { create(:release, :published, version: '3.1.0-dev.1', product:, account:) }

          it 'should upgrade to the dev release' do
            upgrade = subject.upgrade!
            assert upgrade

            expect(upgrade.version).to eq '3.1.0-dev.1'
          end
        end
      end

      context 'when using a constraint' do
        subject { create(:release, :published, version: '2.0.0', product:, account:) }

        it 'should raise for an invalid constraint' do
          expect { subject.upgrade!(constraint: 'invalid') }.to raise_error Semverse::InvalidConstraintFormat
        end

        it 'should upgrade to the latest v2 version' do
          upgrade = subject.upgrade!(constraint: '2')
          assert upgrade

          expect(upgrade.version).to eq '2.9.0'
        end

        it 'should upgrade to the latest v2.x version' do
          upgrade = subject.upgrade!(constraint: '2.0')
          assert upgrade

          expect(upgrade.version).to eq '2.9.0'
        end

        it 'should upgrade to the latest v2.0.x version' do
          upgrade = subject.upgrade!(constraint: '2.1.0')
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
        expect { subject.upgrade! }.to raise_error Keygen::Error::NotFoundError
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

        versions.each { create(:release, :published, version: _1, product:, account:) }
      end

      it 'should not upgrade' do
        upgrade = subject.upgrade

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

        versions.each { create(:release, :published, version: _1, product:, account:) }
      end

      it 'should upgrade' do
        upgrade = subject.upgrade
        assert upgrade

        expect(upgrade.version).to eq '3.0.2'
      end
    end
  end
end
