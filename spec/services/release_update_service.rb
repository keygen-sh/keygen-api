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

  context 'when there are no products' do
    it 'should not return an update when product is nil' do
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

  # TODO(ezekg) alpha

  # TODO(ezekg) dev

  context 'when there is an update available for another platform' do
  end

  context 'when there is no update available for another platform' do
  end

  context 'when there is an update available for the filetype' do
  end

  context 'when there is no update available for the filetype' do
  end

  context 'when there is an update available for a different filetype' do
  end

  context 'when there is no update available for a different filetype' do
  end

  context 'when there is an update for the stable channel' do
  end

  context 'when there is an update for the rc channel' do
  end

  context 'when there is an update for the beta channel' do
  end

  context 'when there is an update for the alpha channel' do
  end

  context 'when there is an update for the dev channel' do
  end

  context 'when there is a new update that was yanked' do
  end

  context 'when the request has version constraints' do
  end

  context 'when the release has entitlement constraints' do
    context 'when the current bearer is an admin' do
    end

    context 'when the current bearer is a product' do
    end

    context 'when the current bearer is a user' do
    end

    context 'when the current bearer is a license' do
    end
  end
end
