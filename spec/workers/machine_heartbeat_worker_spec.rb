# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'
require 'database_cleaner'
require 'sidekiq/testing'

DatabaseCleaner.strategy = :truncation, { except: ['event_types'] }

describe MachineHeartbeatWorker do
  let(:worker) { MachineHeartbeatWorker }

  # See: https://github.com/mhenrixon/sidekiq-unique-jobs#testing
  before do
    Sidekiq::Testing.fake!
    Sidekiq.redis &:flushdb
  end

  after do
    Sidekiq.redis &:flushdb
    Sidekiq::Worker.clear_all
    DatabaseCleaner.clean
  end

  it 'should enqueue and run the worker' do
    machine = create :machine, last_heartbeat_at: nil

    worker.perform_async machine.id
    expect(worker.jobs.size).to eq 1

    worker.drain
    expect(worker.jobs.size).to eq 0
  end

  context 'when there is a machine that does not require heartbeats' do
    let(:machine) { create(:machine, last_heartbeat_at: heartbeat_at) }
    let(:event) { 'machine.heartbeat.pong' }
    let(:heartbeat_at) { nil }

    it 'should not send a webhook event' do
      allow(CreateWebhookEventService).to receive(:new).with(hash_including(event: event)).and_call_original
      expect_any_instance_of(CreateWebhookEventService).not_to receive(:execute)

      worker.perform_async machine.id
      worker.drain
    end

    it 'should not deactivate the machine' do
      worker.perform_async machine.id
      worker.drain

      expect(Machine.count).to eq 1
    end
  end

  context 'when there is a machine that does require heartbeats' do
    context 'when heartbeat is alive' do
      let(:machine) { create(:machine, last_heartbeat_at: heartbeat_at) }
      let(:event) { 'machine.heartbeat.pong' }
      let(:heartbeat_at) { Time.current }

      it 'should send a machine.heartbeat.pong webhook event' do
        events = 0

        allow(CreateWebhookEventService).to receive(:new).with(hash_including(event: event)).and_call_original
        expect_any_instance_of(CreateWebhookEventService).to receive(:execute) { events += 1 }

        worker.perform_async machine.id
        worker.drain

        expect(events).to eq 1
      end

      it 'should not deactivate the machine' do
        worker.perform_async machine.id
        worker.drain

        expect(Machine.count).to eq 1
      end
    end

    context 'when heartbeat is dead' do
      let(:machine) { create(:machine, last_heartbeat_at: heartbeat_at) }
      let(:event) { 'machine.heartbeat.dead' }
      let(:heartbeat_at) { 1.hour.ago }

      it 'should send a machine.heartbeat.dead webhook event' do
        events = 0

        allow(CreateWebhookEventService).to receive(:new).with(hash_including(event: event)).and_call_original
        expect_any_instance_of(CreateWebhookEventService).to receive(:execute) { events += 1 }

        worker.perform_async machine.id
        worker.drain

        expect(events).to eq 1
      end

      it 'should deactivate the machine' do
        worker.perform_async machine.id
        worker.drain

        expect(Machine.count).to eq 0
      end
    end
  end

  context 'when the machine uses the default heartbeat duration' do
    let(:heartbeat_duration) { Machine::HEARTBEAT_TTL + Machine::HEARTBEAT_DRIFT }
    let(:machine) { create(:machine) }
    let(:event) { 'machine.heartbeat.pong' }
    let(:heartbeat_at) { Time.current }

    it 'should be enqueued at the default duration' do
      worker.perform_in heartbeat_duration, machine.id

      job = worker.jobs.last

      expect(job['at'].to_i).to be(job['created_at'].to_i + heartbeat_duration.to_i)
    end
  end

  context 'when the machine uses a custom heartbeat duration' do
    let(:heartbeat_duration) { 7.days }
    let(:policy) { create(:policy, heartbeat_duration: heartbeat_duration ) }
    let(:license) { create(:license, policy: policy ) }
    let(:machine) { create(:machine, license: license ) }
    let(:event) { 'machine.heartbeat.pong' }
    let(:heartbeat_at) { Time.current }

    it 'should be enqueued at the custom duration' do
      worker.perform_in heartbeat_duration, machine.id

      job = worker.jobs.last

      expect(job['at'].to_i).to be(job['created_at'].to_i + heartbeat_duration.to_i)
    end
  end
end