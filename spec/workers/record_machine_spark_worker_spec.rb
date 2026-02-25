# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe RecordMachineSparkWorker, :only_clickhouse do
  before { Sidekiq::Testing.inline! }
  after  { Sidekiq::Testing.fake! }

  it 'should snapshot machine counts for an account' do
    account = create(:account)

    create_list(:machine, 2, account:)

    described_class.perform_async(account.id)

    spark = MachineSpark.for_account(account)
                        .for_environment(nil)
                        .where(created_date: Date.today)
                        .first

    expect(spark&.count).to eq(2)
  end

  it 'should snapshot environment-scoped machine counts' do
    account     = create(:account)
    environment = create(:environment, account:)

    create_list(:machine, 1, account:, environment:)
    create_list(:machine, 4, account:, environment: nil)

    described_class.perform_async(account.id)

    env_spark = MachineSpark.for_account(account)
                            .for_environment(environment)
                            .where(created_date: Date.today)
                            .first

    global_spark = MachineSpark.for_account(account)
                               .for_environment(nil)
                               .where(created_date: Date.today)
                               .first

    expect(env_spark&.count).to eq(1)
    expect(global_spark&.count).to eq(4)
  end
end
