# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe CullDeadMachinesWorker do
  let(:worker)  { CullDeadMachinesWorker }
  let(:account) { create(:account) }

  # See: https://github.com/mhenrixon/sidekiq-unique-jobs#testing
  before do
    Sidekiq::Testing.inline!
  end

  after do
    Sidekiq::Worker.clear_all
  end

  context 'without a monitor' do
    let(:heartbeat_jid) { nil }

    it 'should not cull a machine that is alive' do
      machine = create(:machine, :alive, heartbeat_jid:, account:)

      expect { worker.perform_async }.to_not(
        change { account.machines.count },
      )
    end

    it 'should not cull a machine that is idle' do
      machine = create(:machine, :idle, heartbeat_jid:, account:)

      expect { worker.perform_async }.to_not(
        change { account.machines.count },
      )
    end

    it 'should cull a machine that is dead' do
      machine = create(:machine, :dead, heartbeat_jid:, account:)

      expect { worker.perform_async }.to(
        change { account.machines.count },
      )
    end
  end

  context 'with a monitor' do
    let(:heartbeat_jid) { SecureRandom.hex }

    it 'should not cull a machine that is alive' do
      machine = create(:machine, :alive, heartbeat_jid:, account:)

      expect { worker.perform_async }.to_not(
        change { account.machines.count },
      )
    end

    it 'should not cull a machine that is idle' do
      machine = create(:machine, :idle, heartbeat_jid:, account:)

      expect { worker.perform_async }.to_not(
        change { account.machines.count },
      )
    end

    it 'should not cull a machine that is dead' do
      machine = create(:machine, :dead, heartbeat_jid:, account:)

      expect { worker.perform_async }.to_not(
        change { account.machines.count },
      )
    end
  end

  context 'with 1_MINUTE_REVIVE resurrection strategy' do
    let(:policy)  { create(:policy, heartbeat_resurrection_strategy: '1_MINUTE_REVIVE', heartbeat_cull_strategy: 'DEACTIVATE_DEAD', account:) }
    let(:license) { create(:license, policy:, account:) }

    it 'should not cull a machine that is alive' do
      machine = create(:machine, :alive, license:, account:)

      expect { worker.perform_async }.to_not(
        change { account.machines.count },
      )
    end

    it 'should not cull a machine that is idle' do
      machine = create(:machine, :idle, license:, account:)

      expect { worker.perform_async }.to_not(
        change { account.machines.count },
      )
    end

    it 'should not cull a machine that is dead but not past resurrection period' do
      machine = create(:machine, :dead, last_heartbeat_at: 1.second.ago, license:, account:)

      expect { worker.perform_async }.to_not(
        change { account.machines.count },
      )
    end

    it 'should cull a machine that is dead and past resurrection period' do
      machine = create(:machine, :dead, last_heartbeat_at: 12.minutes.ago, license:, account:)

      expect { worker.perform_async }.to(
        change { account.machines.count },
      )
    end
  end

  context 'with ALWAYS_REVIVE resurrection strategy' do
    let(:policy)  { create(:policy, heartbeat_resurrection_strategy: 'ALWAYS_REVIVE', heartbeat_cull_strategy: 'KEEP_DEAD', account:) }
    let(:license) { create(:license, policy:, account:) }

    it 'should not cull a machine that is alive' do
      machine = create(:machine, :alive, license:, account:)

      expect { worker.perform_async }.to_not(
        change { account.machines.count },
      )
    end

    it 'should not cull a machine that is idle' do
      machine = create(:machine, :idle, license:, account:)

      expect { worker.perform_async }.to_not(
        change { account.machines.count },
      )
    end

    it 'should not cull a machine that is dead' do
      machine = create(:machine, :dead, license:, account:)

      expect { worker.perform_async }.to_not(
        change { account.machines.count },
      )
    end
  end

  context 'with KEEP_DEAD cull strategy' do
    let(:policy)  { create(:policy, heartbeat_resurrection_strategy: 'NO_REVIVE', heartbeat_cull_strategy: 'KEEP_DEAD', account:) }
    let(:license) { create(:license, policy:, account:) }

    it 'should not cull a machine that is alive' do
      machine = create(:machine, :alive, license:, account:)

      expect { worker.perform_async }.to_not(
        change { account.machines.count },
      )
    end

    it 'should not cull a machine that is idle' do
      machine = create(:machine, :idle, license:, account:)

      expect { worker.perform_async }.to_not(
        change { account.machines.count },
      )
    end

    it 'should not cull a machine that is dead' do
      machine = create(:machine, :dead, license:, account:)

      expect { worker.perform_async }.to_not(
        change { account.machines.count },
      )
    end
  end

  context 'when policy heartbeat duration changes' do
    let(:policy)  { create(:policy, require_heartbeat: true, heartbeat_duration: 10.minutes, account:) }
    let(:license) { create(:license, policy:, account:) }

    it 'should cull a machine that is idle' do
      machine = create(:machine, :idle, license:, account:)

      policy.update!(
        heartbeat_duration: 1.hour,
      )

      travel_to 11.minutes.from_now do
        expect { worker.perform_async }.to_not(
          change { account.machines.count },
        )
      end

      travel_to 61.minutes.from_now do
        expect { worker.perform_async }.to(
          change { account.machines.count },
        )
      end
    end

    it 'should not cull a machine that is alive' do
      machine = create(:machine, :alive, license:, account:)

      policy.update!(
        heartbeat_duration: 1.hour,
      )

      travel_to 11.minutes.from_now do
        expect { worker.perform_async }.to_not(
          change { account.machines.count },
        )
      end

      travel_to 61.minutes.from_now do
        expect { worker.perform_async }.to(
          change { account.machines.count },
        )
      end
    end

    it 'should cull a machine that is dead' do
      machine = create(:machine, license:, account:)

      policy.update!(
        heartbeat_duration: 1.hour,
      )

      travel_to 11.minutes.from_now do
        expect { worker.perform_async }.to_not(
          change { account.machines.count },
        )
      end

      travel_to 61.minutes.from_now do
        expect { worker.perform_async }.to(
          change { account.machines.count },
        )
      end
    end
  end

  context 'when policy heartbeat requirement changes' do
    let(:policy)  { create(:policy, require_heartbeat: false, heartbeat_duration: nil, account:) }
    let(:license) { create(:license, policy:, account:) }

    it 'should not cull a machine that is idle' do
      machine = create(:machine, :idle, license:, account:)

      policy.update!(
        heartbeat_duration: 10.minutes,
        require_heartbeat: true,
      )

      expect { worker.perform_async }.to_not(
        change { account.machines.count },
      )

      travel_to 11.minutes.from_now do
        expect { worker.perform_async }.to(
          change { account.machines.count },
        )
      end
    end

    it 'should not cull a machine that is alive' do
      machine = create(:machine, :alive, license:, account:)

      policy.update!(
        heartbeat_duration: 10.minutes,
        require_heartbeat: true,
      )

      expect { worker.perform_async }.to_not(
        change { account.machines.count },
      )

      travel_to 11.minutes.from_now do
        expect { worker.perform_async }.to(
          change { account.machines.count },
        )
      end
    end

    it 'should cull a machine that is dead' do
      machine = create(:machine, :dead, license:, account:)

      policy.update!(
        heartbeat_duration: 10.minutes,
        require_heartbeat: true,
      )

      expect { worker.perform_async }.to(
        change { account.machines.count },
      )

      travel_to 11.minutes.from_now do
        expect { worker.perform_async }.to_not(
          change { account.machines.count },
        )
      end
    end
  end
end
