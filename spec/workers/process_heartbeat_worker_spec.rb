# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe ProcessHeartbeatWorker do
  let(:worker) { ProcessHeartbeatWorker }
  let(:account) { create(:account) }

  # See: https://github.com/mhenrixon/sidekiq-unique-jobs#testing
  before do
    SidekiqUniqueJobs.configure { _1.enabled = true }
  end

  after do
    SidekiqUniqueJobs.configure { _1.enabled = false }
  end

  it 'should enqueue and run the worker' do
    process = create(:machine_process, account:)

    worker.perform_async process.id
    expect(worker.jobs.size).to eq 1

    worker.drain
    expect(worker.jobs.size).to eq 0
  end

  it 'should replace the worker on conflict' do
    process = create(:machine_process, account:)

    worker.perform_async process.id
    worker.perform_async process.id
    worker.perform_async process.id
    expect(worker.jobs.size).to eq 1

    worker.drain
    expect(worker.jobs.size).to eq 0
  end

  context 'when heartbeat is alive' do
    let(:process) { create(:machine_process, last_heartbeat_at:, account:) }
    let(:event) { 'process.heartbeat.pong' }
    let(:last_heartbeat_at) { Time.current }

    it 'should send a process.heartbeat.pong webhook event' do
      expect(BroadcastEventService).to receive(:call) { expect(_1).to include(event:) }.exactly(1).time

      worker.perform_async process.id
      worker.drain
    end

    it 'should not deactivate the process' do
      worker.perform_async process.id
      worker.drain

      expect(MachineProcess.count).to eq 1
    end
  end

  context 'when heartbeat is dead' do
    let(:process) { create(:machine_process, last_heartbeat_at:, account:) }
    let(:event) { 'process.heartbeat.dead' }
    let(:last_heartbeat_at) { 1.hour.ago }

    it 'should send a process.heartbeat.dead webhook event' do
      expect(BroadcastEventService).to receive(:call) { expect(_1).to include(event:) }.exactly(1).time

      worker.perform_async process.id
      worker.drain
    end

    it 'should deactivate the process' do
      worker.perform_async process.id
      worker.drain

      expect(MachineProcess.count).to eq 0
    end

    context 'when policy cull strategy is set to deactivate' do
      let(:policy) { create(:policy, heartbeat_cull_strategy: 'DEACTIVATE_DEAD', account:) }
      let(:license) { create(:license, policy:, account:) }
      let(:machine) { create(:machine, license:, account:) }
      let(:process) { create(:machine_process, last_heartbeat_at:, machine:, account:) }

      it 'should send a process.heartbeat.dead webhook event' do
        expect(BroadcastEventService).to receive(:call) { expect(_1).to include(event:) }.exactly(1).time

        worker.perform_async process.id
        worker.drain
      end

      it 'should deactivate the process' do
        worker.perform_async process.id
        worker.drain

        expect(MachineProcess.count).to eq 0
      end
    end

    context 'when policy cull strategy is set to keep' do
      let(:policy) { create(:policy, heartbeat_cull_strategy: 'KEEP_DEAD', account:) }
      let(:license) { create(:license, policy:, account:) }
      let(:machine) { create(:machine, license:, account:) }
      let(:process) { create(:machine_process, last_heartbeat_at:, machine:, account:) }

      it 'should send a process.heartbeat.dead webhook event' do
        expect(BroadcastEventService).to receive(:call) { expect(_1).to include(event:) }.exactly(1).time

        worker.perform_async process.id
        worker.drain
      end

      it 'should not deactivate the process' do
        worker.perform_async process.id
        worker.drain

        expect(MachineProcess.count).to eq 1
      end
    end

    context 'when policy resurrection strategy is set to always' do
      let(:policy) { create(:policy, heartbeat_resurrection_strategy: 'ALWAYS_REVIVE', heartbeat_cull_strategy: 'KEEP_DEAD', account:) }
      let(:license) { create(:license, policy:, account:) }
      let(:machine) { create(:machine, license:, account:) }
      let(:process) { create(:machine_process, last_heartbeat_at:, machine:, account:) }

      it 'should send a process.heartbeat.dead webhook event' do
        expect(BroadcastEventService).to receive(:call) { expect(_1).to include(event:) }.exactly(1).time

        worker.perform_async process.id
        expect { worker.drain }.to_not raise_error
      end

      it 'should not deactivate the process' do
        worker.perform_async process.id
        worker.drain

        expect(MachineProcess.count).to eq 1
      end
    end

    context 'when policy resurrection strategy is set to 5 minutes' do
      let(:policy) { create(:policy, heartbeat_resurrection_strategy: '5_MINUTE_REVIVE', heartbeat_cull_strategy: 'DEACTIVATE_DEAD', account:) }
      let(:license) { create(:license, policy:, account:) }
      let(:machine) { create(:machine, license:, account:) }
      let(:process) { create(:machine_process, last_heartbeat_at:, machine:, account:) }
      let(:error) { ProcessHeartbeatWorker::ResurrectionPeriodNotPassedError }

      context 'when resurrection period has not passed' do
        let(:last_heartbeat_at) { 11.minutes.ago }

        it 'should send a process.heartbeat.dead webhook event' do
          expect(BroadcastEventService).to receive(:call) { expect(_1).to include(event:) }.exactly(1).time

          worker.perform_async process.id
          expect { worker.drain }.to raise_error error
        end

        it 'should not deactivate the process' do
          worker.perform_async process.id
          expect { worker.drain }.to raise_error error

          expect(MachineProcess.count).to eq 1
        end
      end

      context 'when resurrection period has passed' do
        let(:last_heartbeat_at) { 17.minutes.ago }
        let(:process) { create(:machine_process, last_heartbeat_at:, machine:, account:) }

        it 'should send a process.heartbeat.dead webhook event' do
          expect(BroadcastEventService).to receive(:call) { expect(_1).to include(event:) }.exactly(1).time

          worker.perform_async process.id
          expect { worker.drain }.to_not raise_error
        end

        it 'should deactivate the process' do
          worker.perform_async process.id
          expect { worker.drain }.to_not raise_error

          expect(MachineProcess.count).to eq 0
        end
      end
    end
  end
end
