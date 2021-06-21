# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'
require 'database_cleaner'
require 'sidekiq/testing'

DatabaseCleaner.strategy = :truncation, { except: ['event_types'] }

describe ReleaseUpdateService do
  let(:account) { create(:account) }
  let(:product) { create(:product, account: account) }

  # See: https://github.com/mhenrixon/sidekiq-unique-jobs#testing
  before do
    Sidekiq::Testing.fake!
    Sidekiq.redis(&:flushdb)
  end

  after do
    Sidekiq.redis(&:flushdb)
    Sidekiq::Worker.clear_all
    DatabaseCleaner.clean
  end

  context 'when invalid parameters are supplied to the service' do
    it 'should raise an error when account is nil' do
      updater = -> {
        ReleaseUpdateService.call(
          account: nil,
          product: product,
          platform: 'win32',
          filetype: 'exe',
          version: '1.0.0',
        )
      }

      expect { updater.call }.to raise_error ReleaseUpdateService::InvalidAccountError
    end

    it 'should raise an error when account is not a model' do
      updater = -> {
        ReleaseUpdateService.call(
          account: account.id,
          product: product,
          platform: 'win32',
          filetype: 'exe',
          version: '1.0.0',
        )
      }

      expect { updater.call }.to raise_error ReleaseUpdateService::InvalidAccountError
    end

    it 'should raise an error when product is nil' do
      updater = -> {
        ReleaseUpdateService.call(
          account: account,
          product: nil,
          platform: 'win32',
          filetype: 'exe',
          version: '1.0.0',
        )
      }

      expect { updater.call }.to raise_error ReleaseUpdateService::InvalidProductError
    end

    it 'should raise an error when platform is nil' do
      updater = -> {
        ReleaseUpdateService.call(
          account: account,
          product: account,
          platform: nil,
          filetype: 'exe',
          version: '1.0.0',
        )
      }

      expect { updater.call }.to raise_error ReleaseUpdateService::InvalidPlatformError
    end

    it 'should raise an error when filetype is nil' do
      updater = -> {
        ReleaseUpdateService.call(
          account: account,
          product: account,
          platform: 'win32',
          filetype: nil,
          version: '1.0.0',
        )
      }

      expect { updater.call }.to raise_error ReleaseUpdateService::InvalidFiletypeError
    end

    it 'should raise an error when version is nil' do
      updater = -> {
        ReleaseUpdateService.call(
          account: account,
          product: account,
          platform: 'win32',
          filetype: 'exe',
          version: nil,
        )
      }

      expect { updater.call }.to raise_error ReleaseUpdateService::InvalidVersionError
    end

    it 'should raise an error when channel is nil' do
      updater = -> {
        ReleaseUpdateService.call(
          account: account,
          product: account,
          platform: 'win32',
          filetype: 'exe',
          version: '1.0.0',
          channel: nil,
        )
      }

      expect { updater.call }.to raise_error ReleaseUpdateService::InvalidChannelError
    end

    it 'should raise an error when constraint is not a valid semver' do
      updater = -> {
        ReleaseUpdateService.call(
          account: account,
          product: account,
          platform: 'win32',
          filetype: 'exe',
          version: '1.0.0',
          constraint: 'v8.0.2.1'
        )
      }

      expect { updater.call }.to raise_error ReleaseUpdateService::InvalidConstraintError
    end
  end

  context 'when there are no products' do
    it 'should not return an update when product does not exist' do
      updater = ReleaseUpdateService.call(
        account: account,
        product: SecureRandom.uuid,
        platform: 'win32',
        filetype: 'exe',
        version: '1.0.0',
      )

      expect(updater.current_version).to eq '1.0.0'
      expect(updater.current_release).to be_nil
      expect(updater.next_version).to be_nil
      expect(updater.next_release).to be_nil
    end
  end

  context 'when there are no releases' do
    it 'should not return an update' do
      updater = ReleaseUpdateService.call(
        account: account,
        product: product,
        platform: 'macos',
        filetype: 'dmg',
        version: '0.1.0',
      )

      expect(updater.current_version).to eq '0.1.0'
      expect(updater.current_release).to be_nil
      expect(updater.next_version).to be_nil
      expect(updater.next_release).to be_nil
    end
  end

  context 'when there is an update for the stable channel' do
    let(:platform) { create(:release_platform, key: 'macos', account: account) }
    let(:filetype) { create(:release_filetype, key: 'dmg', account: account) }
    let(:channel) { create(:release_channel, key: 'stable', account: account) }

    let!(:current_release) {
      create(:release,
        platform: platform,
        filename: "#{SecureRandom.hex}.#{filetype.key}",
        filetype: filetype,
        channel: channel,
        version: '1.0.0',
        account: account,
        product: product,
      )
    }

    let!(:next_release) {
      create(:release,
        platform: platform,
        filename: "#{SecureRandom.hex}.#{filetype.key}",
        filetype: filetype,
        channel: channel,
        version: '1.0.1',
        account: account,
        product: product,
      )
    }

    it 'should return an update when current version is not up-to-date' do
      updater = ReleaseUpdateService.call(
        account: account,
        product: product,
        platform: 'macos',
        filetype: 'dmg',
        version: '1.0.0',
        channel: channel,
      )

      expect(updater.current_version).to eq current_release.version
      expect(updater.current_release).to eq current_release
      expect(updater.next_version).to eq next_release.version
      expect(updater.next_release).to eq next_release
    end

    it 'should return an update when current version does not exist' do
      updater = ReleaseUpdateService.call(
        account: account,
        product: product,
        platform: platform,
        filetype: filetype,
        version: '0.1.0',
      )

      expect(updater.current_version).to eq '0.1.0'
      expect(updater.current_release).to be_nil
      expect(updater.next_version).to eq next_release.version
      expect(updater.next_release).to eq next_release
    end

    it 'should not return an update when current version is up-to-date' do
      updater = ReleaseUpdateService.call(
        account: account,
        product: product,
        platform: platform,
        filetype: filetype,
        version: '1.0.1',
      )

      expect(updater.current_version).to eq '1.0.1'
      expect(updater.current_release).to eq next_release
      expect(updater.next_version).to be_nil
      expect(updater.next_release).to be_nil
    end
  end

  context 'when there is an update for the rc channel' do
    let(:platform) { create(:release_platform, key: 'macos', account: account) }
    let(:filetype) { create(:release_filetype, key: 'dmg', account: account) }

    let!(:stable_channel) { create(:release_channel, key: 'stable', account: account) }
    let!(:rc_channel) { create(:release_channel, key: 'rc', account: account) }
    let!(:beta_channel) { create(:release_channel, key: 'beta', account: account) }
    let!(:alpha_channel) { create(:release_channel, key: 'alpha', account: account) }
    let!(:dev_channel) { create(:release_channel, key: 'dev', account: account) }

    let!(:current_release) {
      create(
        :release,
        platform: platform,
        filename: "#{SecureRandom.hex}.#{filetype.key}",
        filetype: filetype,
        channel: stable_channel,
        version: '1.0.0',
        account: account,
        product: product,
      )
    }

    let!(:next_release) {
      create(
        :release,
        platform: platform,
        filename: "#{SecureRandom.hex}.#{filetype.key}",
        filetype: filetype,
        channel: rc_channel,
        version: '1.1.0-rc.3+build.1337',
        account: account,
        product: product,
      )
    }

    it 'should not return an update when update channel is stable' do
      updater = ReleaseUpdateService.call(
        account: account,
        product: product,
        platform: platform,
        filetype: filetype,
        version: '1.0.0',
        channel: 'stable',
      )

      expect(updater.current_version).to eq '1.0.0'
      expect(updater.current_release).to eq current_release
      expect(updater.next_version).to be_nil
      expect(updater.next_release).to be_nil
    end

    it 'should return an update when update channel is rc' do
      updater = ReleaseUpdateService.call(
        account: account,
        product: product,
        platform: platform,
        filetype: filetype,
        version: '1.0.0',
        channel: 'rc',
      )

      expect(updater.current_version).to eq '1.0.0'
      expect(updater.current_release).to eq current_release
      expect(updater.next_version).to eq '1.1.0-rc.3+build.1337'
      expect(updater.next_release).to eq next_release
    end

    it 'should return an update when update channel is beta' do
      updater = ReleaseUpdateService.call(
        account: account,
        product: product,
        platform: platform,
        filetype: filetype,
        version: '1.0.0',
        channel: 'beta',
      )

      expect(updater.current_version).to eq '1.0.0'
      expect(updater.current_release).to eq current_release
      expect(updater.next_version).to eq '1.1.0-rc.3+build.1337'
      expect(updater.next_release).to eq next_release
    end

    it 'should return an update when update channel is alpha' do
      updater = ReleaseUpdateService.call(
        account: account,
        product: product,
        platform: platform,
        filetype: filetype,
        version: '1.0.0',
        channel: 'alpha',
      )

      expect(updater.current_version).to eq '1.0.0'
      expect(updater.current_release).to eq current_release
      expect(updater.next_version).to eq '1.1.0-rc.3+build.1337'
      expect(updater.next_release).to eq next_release
    end

    it 'should not return an update when update channel is dev' do
      updater = ReleaseUpdateService.call(
        account: account,
        product: product,
        platform: platform,
        filetype: filetype,
        version: '1.0.0',
        channel: 'dev',
      )

      expect(updater.current_version).to eq '1.0.0'
      expect(updater.current_release).to eq current_release
      expect(updater.next_version).to be_nil
      expect(updater.next_release).to be_nil
    end
  end

  context 'when there is an update for the beta channel' do
    let(:platform) { create(:release_platform, key: 'macos', account: account) }
    let(:filetype) { create(:release_filetype, key: 'dmg', account: account) }

    let!(:stable_channel) { create(:release_channel, key: 'stable', account: account) }
    let!(:rc_channel) { create(:release_channel, key: 'rc', account: account) }
    let!(:beta_channel) { create(:release_channel, key: 'beta', account: account) }
    let!(:alpha_channel) { create(:release_channel, key: 'alpha', account: account) }
    let!(:dev_channel) { create(:release_channel, key: 'dev', account: account) }

    let!(:current_release) {
      create(
        :release,
        platform: platform,
        filename: "#{SecureRandom.hex}.#{filetype.key}",
        filetype: filetype,
        channel: stable_channel,
        version: '2.1.9',
        account: account,
        product: product,
      )
    }

    let!(:next_release) {
      create(
        :release,
        platform: platform,
        filename: "#{SecureRandom.hex}.#{filetype.key}",
        filetype: filetype,
        channel: beta_channel,
        version: '2.2.0-beta.1',
        account: account,
        product: product,
      )
    }

    it 'should not return an update when update channel is stable' do
      updater = ReleaseUpdateService.call(
        account: account,
        product: product,
        platform: platform,
        filetype: filetype,
        version: '2.1.9',
        channel: stable_channel,
      )

      expect(updater.current_version).to eq '2.1.9'
      expect(updater.current_release).to eq current_release
      expect(updater.next_version).to be_nil
      expect(updater.next_release).to be_nil
    end

    it 'should not return an update when update channel is rc' do
      updater = ReleaseUpdateService.call(
        account: account,
        product: product,
        platform: platform,
        filetype: filetype,
        version: '2.1.9',
        channel: rc_channel,
      )

      expect(updater.current_version).to eq '2.1.9'
      expect(updater.current_release).to eq current_release
      expect(updater.next_version).to be_nil
      expect(updater.next_release).to be_nil
    end

    it 'should return an update when update channel is beta' do
      updater = ReleaseUpdateService.call(
        account: account,
        product: product,
        platform: platform,
        filetype: filetype,
        version: '2.1.9',
        channel: beta_channel,
      )

      expect(updater.current_version).to eq '2.1.9'
      expect(updater.current_release).to eq current_release
      expect(updater.next_version).to eq '2.2.0-beta.1'
      expect(updater.next_release).to eq next_release
    end

    it 'should return an update when update channel is alpha' do
      updater = ReleaseUpdateService.call(
        account: account,
        product: product,
        platform: platform,
        filetype: filetype,
        version: '2.1.9',
        channel: alpha_channel,
      )

      expect(updater.current_version).to eq '2.1.9'
      expect(updater.current_release).to eq current_release
      expect(updater.next_version).to eq '2.2.0-beta.1'
      expect(updater.next_release).to eq next_release
    end

    it 'should not return an update when update channel is dev' do
      updater = ReleaseUpdateService.call(
        account: account,
        product: product,
        platform: platform,
        filetype: filetype,
        version: '2.1.9',
        channel: dev_channel,
      )

      expect(updater.current_version).to eq '2.1.9'
      expect(updater.current_release).to eq current_release
      expect(updater.next_version).to be_nil
      expect(updater.next_release).to be_nil
    end
  end

  context 'when there is an update for the alpha channel' do
    let(:platform) { create(:release_platform, key: 'macos', account: account) }
    let(:filetype) { create(:release_filetype, key: 'dmg', account: account) }

    let!(:stable_channel) { create(:release_channel, key: 'stable', account: account) }
    let!(:rc_channel) { create(:release_channel, key: 'rc', account: account) }
    let!(:beta_channel) { create(:release_channel, key: 'beta', account: account) }
    let!(:alpha_channel) { create(:release_channel, key: 'alpha', account: account) }
    let!(:dev_channel) { create(:release_channel, key: 'dev', account: account) }

    let!(:current_release) {
      create(
        :release,
        platform: platform,
        filename: "#{SecureRandom.hex}.#{filetype.key}",
        filetype: filetype,
        channel: stable_channel,
        version: '2.13.37',
        account: account,
        product: product,
      )
    }

    let!(:next_release) {
      create(
        :release,
        platform: platform,
        filename: "#{SecureRandom.hex}.#{filetype.key}",
        filetype: filetype,
        channel: alpha_channel,
        version: '3.0.0-alpha.1',
        account: account,
        product: product,
      )
    }

    it 'should not return an update when update channel is stable' do
      updater = ReleaseUpdateService.call(
        account: account,
        product: product,
        platform: platform,
        filetype: filetype,
        version: '2.13.37',
        channel: stable_channel,
      )

      expect(updater.current_version).to eq '2.13.37'
      expect(updater.current_release).to eq current_release
      expect(updater.next_version).to be_nil
      expect(updater.next_release).to be_nil
    end

    it 'should not return an update when update channel is rc' do
      updater = ReleaseUpdateService.call(
        account: account,
        product: product,
        platform: platform,
        filetype: filetype,
        version: '2.13.37',
        channel: rc_channel,
      )

      expect(updater.current_version).to eq '2.13.37'
      expect(updater.current_release).to eq current_release
      expect(updater.next_version).to be_nil
      expect(updater.next_release).to be_nil
    end

    it 'should not return an update when update channel is beta' do
      updater = ReleaseUpdateService.call(
        account: account,
        product: product,
        platform: platform,
        filetype: filetype,
        version: '2.13.37',
        channel: beta_channel,
      )

      expect(updater.current_version).to eq '2.13.37'
      expect(updater.current_release).to eq current_release
      expect(updater.next_version).to be_nil
      expect(updater.next_release).to be_nil
    end

    it 'should return an update when update channel is alpha' do
      updater = ReleaseUpdateService.call(
        account: account,
        product: product,
        platform: platform,
        filetype: filetype,
        version: '2.13.37',
        channel: alpha_channel,
      )

      expect(updater.current_version).to eq '2.13.37'
      expect(updater.current_release).to eq current_release
      expect(updater.next_version).to eq '3.0.0-alpha.1'
      expect(updater.next_release).to eq next_release
    end

    it 'should not return an update when update channel is dev' do
      updater = ReleaseUpdateService.call(
        account: account,
        product: product,
        platform: platform,
        filetype: filetype,
        version: '2.13.37',
        channel: dev_channel,
      )

      expect(updater.current_version).to eq '2.13.37'
      expect(updater.current_release).to eq current_release
      expect(updater.next_version).to be_nil
      expect(updater.next_release).to be_nil
    end
  end

  context 'when there is an update for the dev channel' do
    let(:platform) { create(:release_platform, key: 'macos', account: account) }
    let(:filetype) { create(:release_filetype, key: 'dmg', account: account) }

    let!(:stable_channel) { create(:release_channel, key: 'stable', account: account) }
    let!(:rc_channel) { create(:release_channel, key: 'rc', account: account) }
    let!(:beta_channel) { create(:release_channel, key: 'beta', account: account) }
    let!(:alpha_channel) { create(:release_channel, key: 'alpha', account: account) }
    let!(:dev_channel) { create(:release_channel, key: 'dev', account: account) }

    let!(:current_release) {
      create(
        :release,
        platform: platform,
        filename: "#{SecureRandom.hex}.#{filetype.key}",
        filetype: filetype,
        channel: stable_channel,
        version: '1.0.0',
        account: account,
        product: product,
      )
    }

    let!(:next_release) {
      create(
        :release,
        platform: platform,
        filename: "#{SecureRandom.hex}.#{filetype.key}",
        filetype: filetype,
        channel: dev_channel,
        version: '1.1.0-dev.93+build.1624032445',
        account: account,
        product: product,
      )
    }

    it 'should not return an update when update channel is stable' do
      updater = ReleaseUpdateService.call(
        account: account,
        product: product.id,
        platform: platform.id,
        filetype: filetype.id,
        version: '1.0.0',
        channel: stable_channel.id,
      )

      expect(updater.current_version).to eq '1.0.0'
      expect(updater.current_release).to eq current_release
      expect(updater.next_version).to be_nil
      expect(updater.next_release).to be_nil
    end

    it 'should not return an update when update channel is rc' do
      updater = ReleaseUpdateService.call(
        account: account,
        product: product.id,
        platform: platform.id,
        filetype: filetype.id,
        version: '1.0.0',
        channel: rc_channel.id,
      )

      expect(updater.current_version).to eq '1.0.0'
      expect(updater.current_release).to eq current_release
      expect(updater.next_version).to be_nil
      expect(updater.next_release).to be_nil
    end

    it 'should not return an update when update channel is beta' do
      updater = ReleaseUpdateService.call(
        account: account,
        product: product.id,
        platform: platform.id,
        filetype: filetype.id,
        version: '1.0.0',
        channel: beta_channel.id,
      )

      expect(updater.current_version).to eq '1.0.0'
      expect(updater.current_release).to eq current_release
      expect(updater.next_version).to be_nil
      expect(updater.next_release).to be_nil
    end

    it 'should not return an update when update channel is alpha' do
      updater = ReleaseUpdateService.call(
        account: account,
        product: product.id,
        platform: platform.id,
        filetype: filetype.id,
        version: '1.0.0',
        channel: alpha_channel.id,
      )

      expect(updater.current_version).to eq '1.0.0'
      expect(updater.current_release).to eq current_release
      expect(updater.next_version).to be_nil
      expect(updater.next_release).to be_nil
    end

    it 'should return an update when update channel is dev' do
      updater = ReleaseUpdateService.call(
        account: account,
        product: product.id,
        platform: platform.id,
        filetype: filetype.id,
        version: '1.0.0',
        channel: dev_channel.id,
      )

      expect(updater.current_version).to eq '1.0.0'
      expect(updater.current_release).to eq current_release
      expect(updater.next_version).to eq '1.1.0-dev.93+build.1624032445'
      expect(updater.next_release).to eq next_release
    end
  end

  context 'when the current version has been yanked' do
    let(:platform) { create(:release_platform, key: 'linux', account: account) }
    let(:filetype) { create(:release_filetype, key: 'tar.gz', account: account) }
    let(:channel) { create(:release_channel, key: 'stable', account: account) }

    let!(:current_release) {
      create(
        :release,
        yanked_at: Time.current,
        platform: platform,
        filename: "#{SecureRandom.hex}.#{filetype.key}",
        filetype: filetype,
        channel: channel,
        version: '1.0.0',
        account: account,
        product: product,
      )
    }

    let!(:next_release) {
      create(
        :release,
        platform: platform,
        filename: "#{SecureRandom.hex}.#{filetype.key}",
        filetype: filetype,
        channel: channel,
        version: '2.0.0+build.1624035574',
        account: account,
        product: product,
      )
    }

    it 'should return the current version that is yanked' do
      updater = ReleaseUpdateService.call(
        account: account,
        product: product,
        platform: 'linux',
        filetype: 'tar.gz',
        version: '1.0.0',
      )

      expect(updater.current_version).to eq '1.0.0'
      expect(updater.current_release).to eq current_release
      expect(updater.next_version).to eq '2.0.0+build.1624035574'
      expect(updater.next_release).to eq next_release
    end
  end

  context 'when the next version has been yanked' do
    let(:platform) { create(:release_platform, key: 'win32', account: account) }
    let(:filetype) { create(:release_filetype, key: 'exe', account: account) }
    let(:channel) { create(:release_channel, key: 'stable', account: account) }

    let!(:current_release) {
      create(
        :release,
        platform: platform,
        filename: "#{SecureRandom.hex}.#{filetype.key}",
        filetype: filetype,
        channel: channel,
        version: '1.0.0',
        account: account,
        product: product,
      )
    }

    let!(:next_release) {
      create(
        :release,
        yanked_at: Time.current,
        platform: platform,
        filename: "#{SecureRandom.hex}.#{filetype.key}",
        filetype: filetype,
        channel: channel,
        version: '2.0.0+build.1624035574',
        account: account,
        product: product,
      )
    }

    it 'should not return the next version that is yanked' do
      updater = ReleaseUpdateService.call(
        account: account,
        product: product,
        platform: 'win32',
        filetype: 'exe',
        version: '1.0.0',
      )

      expect(updater.current_version).to eq '1.0.0'
      expect(updater.current_release).to eq current_release
      expect(updater.next_version).to be_nil
      expect(updater.next_release).to be_nil
    end
  end

  context 'when the release versions contain build tags' do
    let(:platform) { create(:release_platform, key: 'macos', account: account) }
    let(:filetype) { create(:release_filetype, key: 'dmg', account: account) }
    let(:channel) { create(:release_channel, key: 'stable', account: account) }

    let!(:current_release) {
      create(:release,
        platform: platform,
        filename: "#{SecureRandom.hex}.#{filetype.key}",
        filetype: filetype,
        channel: channel,
        version: '1.0.0+build.1624288707',
        account: account,
        product: product,
      )
    }

    let!(:next_release) {
      create(:release,
        platform: platform,
        filename: "#{SecureRandom.hex}.#{filetype.key}",
        filetype: filetype,
        channel: channel,
        version: '1.0.1+build.1624288716',
        account: account,
        product: product,
      )
    }

    it 'should return an update result with a nil current release when version is not exact' do
      updater = ReleaseUpdateService.call(
        account: account,
        product: product,
        platform: 'macos',
        filetype: 'dmg',
        version: '1.0.0',
        channel: channel,
      )

      expect(updater.current_version).to eq '1.0.0'
      expect(updater.current_release).to be_nil
      expect(updater.next_version).to eq next_release.version
      expect(updater.next_release).to eq next_release
      expect(updater.next_release.semver.build).to eq 'build.1624288716'
    end

    it 'should return an update result with the current release when the version is exact' do
      updater = ReleaseUpdateService.call(
        account: account,
        product: product,
        platform: 'macos',
        filetype: 'dmg',
        version: '1.0.0+build.1624288707',
        channel: channel,
      )

      expect(updater.current_version).to eq current_release.version
      expect(updater.current_release).to eq current_release
      expect(updater.current_release.semver.build).to eq 'build.1624288707'
      expect(updater.next_version).to eq next_release.version
      expect(updater.next_release).to eq next_release
      expect(updater.next_release.semver.build).to eq 'build.1624288716'
    end
  end

  context 'when there is an update available for another platform' do
    let(:macos_platform) { create(:release_platform, key: 'macos', account: account) }
    let(:win32_platform) { create(:release_platform, key: 'win32', account: account) }
    let(:filetype) { create(:release_filetype, key: 'tar.gz', account: account) }
    let(:channel) { create(:release_channel, key: 'stable', account: account) }

    let!(:current_release) {
      create(:release,
        platform: macos_platform,
        filename: "#{SecureRandom.hex}.#{filetype.key}",
        filetype: filetype,
        channel: channel,
        version: '1.0.0',
        account: account,
        product: product,
      )
    }

    let!(:next_release) {
      create(:release,
        platform: win32_platform,
        filename: "#{SecureRandom.hex}.#{filetype.key}",
        filetype: filetype,
        channel: channel,
        version: '2.0.0',
        account: account,
        product: product,
      )
    }

    it 'should not return an update for the other platform' do
      updater = ReleaseUpdateService.call(
        account: account,
        product: product,
        platform: 'macos',
        filetype: 'tar.gz',
        version: '1.0.0',
        channel: channel,
      )

      expect(updater.current_version).to eq current_release.version
      expect(updater.current_release).to eq current_release
      expect(updater.next_version).to be_nil
      expect(updater.next_release).to be_nil
    end
  end

  context 'when there is an update available for another filetype' do
    let(:platform) { create(:release_platform, key: 'win32', account: account) }
    let(:exe_filetype) { create(:release_filetype, key: 'exe', account: account) }
    let(:msi_filetype) { create(:release_filetype, key: 'msi', account: account) }
    let(:channel) { create(:release_channel, key: 'stable', account: account) }

    let!(:current_release) {
      create(:release,
        platform: platform,
        filename: "#{SecureRandom.hex}.#{exe_filetype.key}",
        filetype: exe_filetype,
        channel: channel,
        version: '1.0.0',
        account: account,
        product: product,
      )
    }

    let!(:next_release) {
      create(:release,
        platform: platform,
        filename: "#{SecureRandom.hex}.#{msi_filetype.key}",
        filetype: msi_filetype,
        channel: channel,
        version: '2.0.0',
        account: account,
        product: product,
      )
    }

    it 'should not return an update for the other filetype' do
      updater = ReleaseUpdateService.call(
        account: account,
        product: product,
        platform: 'win32',
        filetype: 'exe',
        version: '1.0.0',
        channel: channel,
      )

      expect(updater.current_version).to eq current_release.version
      expect(updater.current_release).to eq current_release
      expect(updater.next_version).to be_nil
      expect(updater.next_release).to be_nil
    end
  end

  context 'when the request supplies a version constraint' do
    let(:platform) { create(:release_platform, key: 'win32', account: account) }
    let(:filetype) { create(:release_filetype, key: 'exe', account: account) }
    let(:channel) { create(:release_channel, key: 'stable', account: account) }

    let!(:current_release) {
      create(:release,
        platform: platform,
        filename: "#{SecureRandom.hex}.#{filetype.key}",
        filetype: filetype,
        channel: channel,
        version: '1.0.0',
        account: account,
        product: product,
      )
    }

    let!(:next_patch_release) {
      create(:release,
        platform: platform,
        filename: "#{SecureRandom.hex}.#{filetype.key}",
        filetype: filetype,
        channel: channel,
        version: '1.0.83+build.1624289491',
        account: account,
        product: product,
      )
    }

    let!(:next_minor_release) {
      create(:release,
        platform: platform,
        filename: "#{SecureRandom.hex}.#{filetype.key}",
        filetype: filetype,
        channel: channel,
        version: '1.5.0',
        account: account,
        product: product,
      )
    }

    let!(:next_major_release) {
      create(:release,
        platform: platform,
        filename: "#{SecureRandom.hex}.#{filetype.key}",
        filetype: filetype,
        channel: channel,
        version: '2.0.0',
        account: account,
        product: product,
      )
    }

    it 'should return a patch update when version is constrained to 1.0.0' do
      updater = ReleaseUpdateService.call(
        account: account,
        product: product,
        platform: 'win32',
        filetype: 'exe',
        version: '1.0.0',
        channel: channel,
        constraint: '1.0.0',
      )

      expect(updater.current_version).to eq current_release.version
      expect(updater.current_release).to eq current_release
      expect(updater.next_version).to eq next_patch_release.version
      expect(updater.next_release).to eq next_patch_release
    end

    it 'should return a minor update when version is constrained to 1.0' do
      updater = ReleaseUpdateService.call(
        account: account,
        product: product,
        platform: 'win32',
        filetype: 'exe',
        version: '1.0.0',
        channel: channel,
        constraint: '1.0',
      )

      expect(updater.current_version).to eq current_release.version
      expect(updater.current_release).to eq current_release
      expect(updater.next_version).to eq next_minor_release.version
      expect(updater.next_release).to eq next_minor_release
    end

    it 'should return major update when version is constrained to 2.0' do
      updater = ReleaseUpdateService.call(
        account: account,
        product: product,
        platform: 'win32',
        filetype: 'exe',
        version: '1.0.0',
        channel: channel,
        constraint: '2.0',
      )

      expect(updater.current_version).to eq current_release.version
      expect(updater.current_release).to eq current_release
      expect(updater.next_version).to eq next_major_release.version
      expect(updater.next_release).to eq next_major_release
    end
  end
end
