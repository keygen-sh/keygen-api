# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe MachineHeartbeatWorker do
  let(:worker) { MachineHeartbeatWorker }
  let(:account) { create(:account) }

  # See: https://github.com/mhenrixon/sidekiq-unique-jobs#testing
  before do
    SidekiqUniqueJobs.configure { _1.enabled = true }
  end

  after do
    SidekiqUniqueJobs.configure { _1.enabled = false }
  end

  it 'should enqueue and run the worker' do
    machine = create :machine, last_heartbeat_at: nil, account: account

    worker.perform_async machine.id
    expect(worker.jobs.size).to eq 1

    worker.drain
    expect(worker.jobs.size).to eq 0
  end

  it 'should replace the worker on conflict' do
    machine = create :machine, last_heartbeat_at: nil, account: account

    worker.perform_async machine.id
    worker.perform_async machine.id
    worker.perform_async machine.id
    expect(worker.jobs.size).to eq 1

    worker.drain
    expect(worker.jobs.size).to eq 0
  end

  context 'when there is a machine that does not require heartbeats' do
    let(:machine) { create(:machine, last_heartbeat_at: heartbeat_at, account: account) }
    let(:event) { 'machine.heartbeat.pong' }
    let(:heartbeat_at) { nil }

    it 'should not send a webhook event' do
      expect(BroadcastEventService).to receive(:call) { expect(_1).to include(event:) }.exactly(0).times

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
      let(:machine) { create(:machine, last_heartbeat_at: heartbeat_at, account: account) }
      let(:event) { 'machine.heartbeat.pong' }
      let(:heartbeat_at) { Time.current }

      it 'should send a machine.heartbeat.pong webhook event' do
        expect(BroadcastEventService).to receive(:call) { expect(_1).to include(event:) }.exactly(1).time

        worker.perform_async machine.id
        worker.drain
      end

      it 'should not deactivate the machine' do
        worker.perform_async machine.id
        worker.drain

        expect(Machine.count).to eq 1
      end
    end

    context 'when heartbeat is dead' do
      let(:machine) { create(:machine, last_heartbeat_at: heartbeat_at, account: account) }
      let(:event) { 'machine.heartbeat.dead' }
      let(:heartbeat_at) { 1.hour.ago }

      it 'should send a machine.heartbeat.dead webhook event' do
        expect(BroadcastEventService).to receive(:call) { expect(_1).to include(event:) }.exactly(1).time

        worker.perform_async machine.id
        worker.drain
      end

      it 'should deactivate the machine' do
        worker.perform_async machine.id
        worker.drain

        expect(Machine.count).to eq 0
      end

      context 'when policy cull strategy is set to deactivate' do
        let(:policy) { create(:policy, heartbeat_cull_strategy: 'DEACTIVATE_DEAD', account: account) }
        let(:license) { create(:license, policy: policy, account: account) }
        let(:machine) { create(:machine, last_heartbeat_at: heartbeat_at, license: license, account: account) }

        it 'should send a machine.heartbeat.dead webhook event' do
          expect(BroadcastEventService).to receive(:call) { expect(_1).to include(event:) }.exactly(1).time

          worker.perform_async machine.id
          worker.drain
        end

        it 'should deactivate the machine' do
          worker.perform_async machine.id
          worker.drain

          expect(Machine.count).to eq 0
        end
      end

      context 'when policy cull strategy is set to keep' do
        let(:policy) { create(:policy, heartbeat_cull_strategy: 'KEEP_DEAD', account: account) }
        let(:license) { create(:license, policy: policy, account: account) }
        let(:machine) { create(:machine, last_heartbeat_at: heartbeat_at, license: license, account: account) }

        it 'should send a machine.heartbeat.dead webhook event' do
          expect(BroadcastEventService).to receive(:call) { expect(_1).to include(event:) }.exactly(1).time

          worker.perform_async machine.id
          worker.drain
        end

        it 'should not deactivate the machine' do
          worker.perform_async machine.id
          worker.drain

          expect(Machine.count).to eq 1
        end
      end

      context 'when policy resurrection strategy is set to always' do
        let(:policy) { create(:policy, heartbeat_resurrection_strategy: 'ALWAYS_REVIVE', heartbeat_cull_strategy: 'KEEP_DEAD', account: account) }
        let(:license) { create(:license, policy: policy, account: account) }
        let(:machine) { create(:machine, last_heartbeat_at: heartbeat_at, license: license, account: account) }

        it 'should send a machine.heartbeat.dead webhook event' do
          expect(BroadcastEventService).to receive(:call) { expect(_1).to include(event:) }.exactly(1).time

          worker.perform_async machine.id
          expect { worker.drain }.to_not raise_error
        end

        it 'should not deactivate the machine' do
          worker.perform_async machine.id
          worker.drain

          expect(Machine.count).to eq 1
        end
      end

      context 'when policy resurrection strategy is set to 5 minutes' do
        let(:policy) { create(:policy, heartbeat_resurrection_strategy: '5_MINUTE_REVIVE', heartbeat_cull_strategy: 'DEACTIVATE_DEAD', account: account) }
        let(:machine) { create(:machine, last_heartbeat_at: heartbeat_at, license: license, account: account) }
        let(:license) { create(:license, policy: policy, account: account) }
        let(:error) { MachineHeartbeatWorker::ResurrectionPeriodNotPassedError }

        context 'when resurrection period has not passed' do
          let(:heartbeat_at) { 11.minutes.ago }

          it 'should send a machine.heartbeat.dead webhook event' do
            expect(BroadcastEventService).to receive(:call) { expect(_1).to include(event:) }.exactly(1).time

            worker.perform_async machine.id
            expect { worker.drain }.to raise_error error
          end

          it 'should not deactivate the machine' do
            worker.perform_async machine.id
            expect { worker.drain }.to raise_error error

            expect(Machine.count).to eq 1
          end
        end

        context 'when resurrection period has passed' do
          let(:heartbeat_at) { 17.minutes.ago }
          let(:machine) { create(:machine, last_heartbeat_at: heartbeat_at, license: license, account: account) }

          it 'should send a machine.heartbeat.dead webhook event' do
            expect(BroadcastEventService).to receive(:call) { expect(_1).to include(event:) }.exactly(1).time

            worker.perform_async machine.id
            expect { worker.drain }.to_not raise_error
          end

          it 'should deactivate the machine' do
            worker.perform_async machine.id
            expect { worker.drain }.to_not raise_error

            expect(Machine.count).to eq 0
          end
        end
      end
    end
  end

  context 'when the machine uses the default heartbeat duration' do
    let(:heartbeat_duration) { Machine::HEARTBEAT_TTL + Machine::HEARTBEAT_DRIFT }
    let(:machine) { create(:machine, account: account) }
    let(:event) { 'machine.heartbeat.pong' }
    let(:heartbeat_at) { Time.current }

    it 'should be enqueued at the default duration' do
      worker.perform_in heartbeat_duration, machine.id

      job = worker.jobs.last

      expect(job['at'].to_i).to be_within(30.seconds).of(
        job['created_at'].to_i + heartbeat_duration.to_i,
      )
    end
  end

  context 'when the machine uses a custom heartbeat duration' do
    let(:heartbeat_duration) { 7.days }
    let(:policy) { create(:policy, heartbeat_duration: heartbeat_duration, account: account) }
    let(:license) { create(:license, policy: policy, account: account) }
    let(:machine) { create(:machine, license: license, account: account) }
    let(:event) { 'machine.heartbeat.pong' }
    let(:heartbeat_at) { Time.current }

    it 'should be enqueued at the custom duration' do
      worker.perform_in heartbeat_duration, machine.id

      job = worker.jobs.last

      expect(job['at'].to_i).to be_within(30.seconds).of(
        job['created_at'].to_i + heartbeat_duration.to_i,
      )
    end
  end
end
