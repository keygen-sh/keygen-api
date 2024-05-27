# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe CullDeadProcessesWorker do
  let(:worker)  { CullDeadProcessesWorker }
  let(:account) { create(:account) }

  before { Sidekiq::Testing.inline! }
  after  { Sidekiq::Testing.fake! }

  context 'without a monitor' do
    let(:heartbeat_jid) { nil }

    it 'should not cull a process that is alive' do
      process = create(:process, :alive, heartbeat_jid:, account:)

      expect { worker.perform_async }.to_not(
        change { account.machine_processes.count },
      )
    end

    it 'should cull a process that is dead' do
      process = create(:process, :dead, heartbeat_jid:, account:)

      expect { worker.perform_async }.to(
        change { account.machine_processes.count },
      )
    end
  end

  context 'with a monitor' do
    let(:heartbeat_jid) { SecureRandom.hex }

    it 'should not cull a process that is alive' do
      process = create(:process, :alive, heartbeat_jid:, account:)

      expect { worker.perform_async }.to_not(
        change { account.machine_processes.count },
      )
    end

    it 'should not cull a process that is dead' do
      process = create(:process, :dead, heartbeat_jid:, account:)

      expect { worker.perform_async }.to_not(
        change { account.machine_processes.count },
      )
    end
  end

  context 'when policy heartbeat duration changes' do
    let(:policy)  { create(:policy, require_heartbeat: true, heartbeat_duration: 10.minutes, account:) }
    let(:license) { create(:license, policy:, account:) }
    let(:machine) { create(:machine, license:, account:) }

    it 'should cull a process that is dead' do
      process = create(:process, machine:, account:)

      policy.update!(
        heartbeat_duration: 1.hour,
      )

      travel_to 11.minutes.from_now do
        expect { worker.perform_async }.to_not(
          change { account.machine_processes.count },
        )
      end

      travel_to 61.minutes.from_now do
        expect { worker.perform_async }.to(
          change { account.machine_processes.count },
        )
      end
    end
  end
end
