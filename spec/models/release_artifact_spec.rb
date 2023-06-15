# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe ReleaseArtifact, type: :model do
  let(:account) { create(:account) }
  let(:product) { create(:product, account:) }

  it_behaves_like :environmental

  describe '#environment=' do
    context 'on create' do
      it 'should apply default environment matching release' do
        environment = create(:environment, account:)
        release     = create(:release, account:, environment:)
        artifact    = create(:artifact, account:, release:)

        expect(artifact.environment).to eq release.environment
      end

      it 'should not raise when environment matches release' do
        environment = create(:environment, account:)
        release     = create(:release, account:, environment:)

        expect { create(:artifact, account:, environment:, release:) }.to_not raise_error
      end

      it 'should raise when environment does not match release' do
        environment = create(:environment, account:)
        release     = create(:release, account:, environment: nil)

        expect { create(:artifact, account:, environment:, release:) }.to raise_error ActiveRecord::RecordInvalid
      end
    end

    context 'on update' do
      it 'should not raise when environment matches release' do
        environment = create(:environment, account:)
        artifact    = create(:artifact, account:, environment:)

        expect { artifact.update!(release: create(:release, account:, environment:)) }.to_not raise_error
      end

      it 'should raise when environment does not match release' do
        environment = create(:environment, account:)
        artifact    = create(:artifact, account:, environment:)

        expect { artifact.update!(release: create(:release, account:, environment: nil)) }.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end

  describe '.without_constraints' do
    let(:artifacts) { described_class.where(account:) }

    before do
      r0 = create(:release, constraints: [build(:constraint, account:)], product:, account:)
      r1 = create(:release, product:, account:)

      create(:artifact, release: r0, account:)
      create(:artifact, release: r1, account:)
    end

    it 'should filter artifacts without releases constraints' do
      expect(artifacts.without_constraints.ids).to match_array [artifacts.second.id]
    end
  end

  describe '.with_constraints' do
    let(:artifacts) { described_class.where(account:) }

    before do
      r0 = create(:release, constraints: [build(:constraint, account:)], product:, account:)
      r1 = create(:release, product:, account:)

      create(:artifact, release: r0, account:)
      create(:artifact, release: r1, account:)
    end

    it 'should filter artifacts with releases constraints' do
      expect(artifacts.with_constraints.ids).to match_array [artifacts.first.id]
    end
  end

  describe '.within_constraints' do
    let(:artifacts) { described_class.where(account:) }

    before do
      e0 = create(:entitlement, code: 'A', account:)
      e1 = create(:entitlement, code: 'B', account:)
      e2 = create(:entitlement, code: 'C', account:)
      e3 = create(:entitlement, code: 'D', account:)
      e4 = create(:entitlement, code: 'E', account:)

      r0 = create(:release, constraints: [build(:constraint, entitlement: e0, account:), build(:constraint, entitlement: e1, account:), build(:constraint, entitlement: e2, account:), build(:constraint, entitlement: e3, account:)], product:, account:)
      r1 = create(:release, constraints: [build(:constraint, entitlement: e0, account:), build(:constraint, entitlement: e1, account:), build(:constraint, entitlement: e2, account:)], product:, account:)
      r2 = create(:release, constraints: [build(:constraint, entitlement: e0, account:), build(:constraint, entitlement: e2, account:)], product:, account:)
      r3 = create(:release, constraints: [build(:constraint, entitlement: e0, account:)], product:, account:)
      r4 = create(:release, product:, account:)
      r5 = create(:release, constraints: [build(:constraint, entitlement: e4, account:)], product:, account:)

      create(:artifact, release: r0, account:)
      create(:artifact, release: r1, account:)
      create(:artifact, release: r2, account:)
      create(:artifact, release: r3, account:)
      create(:artifact, release: r4, account:)
      create(:artifact, release: r5, account:)
    end

    context 'strict mode disabled' do
      it 'should filter artifacts within release constraints' do
        expect(artifacts.within_constraints('A', 'B', 'C', strict: false).ids).to match_array [
          artifacts.first.id,
          artifacts.second.id,
          artifacts.third.id,
          artifacts.fourth.id,
          artifacts.fifth.id,
        ]
      end
    end

    context 'strict mode enabled' do
      it 'should filter artifacts within release constraints' do
        expect(artifacts.within_constraints('A', 'B', 'C', strict: true).ids).to match_array [
          artifacts.second.id,
          artifacts.third.id,
          artifacts.fourth.id,
          artifacts.fifth.id,
        ]
      end
    end

    it 'should filter artifacts without releases constraints' do
      expect(artifacts.within_constraints.ids).to match_array [
        artifacts.fifth.id,
      ]
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

      releases  = versions.map { create(:release, :published, version: _1, product:, account:) }
      artifacts = releases.map { create(:artifact, :uploaded, release: _1, account:) }
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

    it 'should take latest' do
      artifact = described_class.order_by_version
                                .take

      expect(artifact.version).to eq '101.0.0'
    end
  end

  describe 'filesize=' do
    it 'should not raise on positive filesize' do
      expect { create(:artifact, filesize: 1, account:) }.to_not raise_error
    end

    it 'should raise on negative filesize' do
      expect { create(:artifact, filesize: -1, account:) }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'should raise on filesize > 5GB' do
      expect { create(:artifact, filesize: 5.gigabytes + 1.kilobyte, account:) }.to raise_error ActiveRecord::RecordInvalid
    end
  end
end
