# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe ChangeAliveStatusToNotStartedForMachineMigration do
  let(:account) { create(:account) }

  before do
    RequestMigrations.configure do |config|
      config.current_version = '1.3'
      config.versions        = {
        '1.3' => [ChangeAliveStatusToNotStartedForMachineMigration],
      }
    end
  end

  context 'the machine is not started' do
    subject { create(:machine, last_heartbeat_at: nil, account:) }

    it "should not migrate a machine's status" do
      migrator = RequestMigrations::Migrator.new(from: '1.3', to: '1.3')
      data     = Keygen::JSONAPI.render(subject)

      expect(data).to include(
        data: include(
          attributes: include(
            heartbeatStatus: 'NOT_STARTED',
            lastHeartbeat: nil,
          ),
        ),
      )

      migrator.migrate!(data:)

      expect(data).to include(
        data: include(
          attributes: include(
            heartbeatStatus: 'NOT_STARTED',
            lastHeartbeat: nil,
          ),
        ),
      )
    end
  end

  context 'the machine is alive' do
    subject { create(:machine, last_heartbeat_at: Time.current, account:) }

    it "should migrate a machine's status" do
      migrator = RequestMigrations::Migrator.new(from: '1.3', to: '1.3')
      data     = Keygen::JSONAPI.render(subject)

      expect(data).to include(
        data: include(
          attributes: include(
            heartbeatStatus: 'ALIVE',
            lastHeartbeat: Time,
          ),
        ),
      )

      migrator.migrate!(data:)

      expect(data).to include(
        data: include(
          attributes: include(
            heartbeatStatus: 'NOT_STARTED',
            lastHeartbeat: nil,
          ),
        ),
      )
    end
  end

  context 'the machine is dead' do
    subject { create(:machine, last_heartbeat_at: 1.day.ago, account:) }

    it "should not migrate a machine's status" do
      migrator = RequestMigrations::Migrator.new(from: '1.3', to: '1.3')
      data     = Keygen::JSONAPI.render(subject)

      expect(data).to include(
        data: include(
          attributes: include(
            heartbeatStatus: 'DEAD',
            lastHeartbeat: Time,
          ),
        ),
      )

      migrator.migrate!(data:)

      expect(data).to include(
        data: include(
          attributes: include(
            heartbeatStatus: 'DEAD',
            lastHeartbeat: Time,
          ),
        ),
      )
    end
  end
end
