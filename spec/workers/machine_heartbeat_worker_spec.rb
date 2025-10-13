# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe MachineHeartbeatWorker do
  let(:worker) { MachineHeartbeatWorker }
  let(:account) { create(:account) }

  context 'when there is a machine that does not require heartbeats' do
    let(:machine) { create(:machine, last_heartbeat_at: heartbeat_at, account: account) }
    let(:event) { 'machine.heartbeat.pong' }
    let(:heartbeat_at) { nil }

    it 'should not send a webhook event' do
      expect(BroadcastEventService).to receive(:call) { expect(it).to include(event:) }.exactly(0).times

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
        expect(BroadcastEventService).to receive(:call) { expect(it).to include(event:) }.exactly(1).time

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
        expect(BroadcastEventService).to receive(:call) { expect(it).to include(event:) }.exactly(1).time

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
          expect(BroadcastEventService).to receive(:call) { expect(it).to include(event:) }.exactly(1).time

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
          expect(BroadcastEventService).to receive(:call) { expect(it).to include(event:) }.exactly(1).time

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
          expect(BroadcastEventService).to receive(:call) { expect(it).to include(event:) }.exactly(1).time

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
            expect(BroadcastEventService).to receive(:call) { expect(it).to include(event:) }.exactly(1).time

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
            expect(BroadcastEventService).to receive(:call) { expect(it).to include(event:) }.exactly(1).time

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
end
