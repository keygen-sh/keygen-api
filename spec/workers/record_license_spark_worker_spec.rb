# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe RecordLicenseSparkWorker, :only_clickhouse do
  before { Sidekiq::Testing.inline! }
  after  { Sidekiq::Testing.fake! }

  it 'should snapshot license counts for an account' do
    account = create(:account)

    create_list(:license, 3, account:)

    described_class.perform_async(account.id)

    spark = LicenseSpark.for_account(account)
                        .for_environment(nil)
                        .where(created_date: Date.today)
                        .first

    expect(spark&.count).to eq(3)
  end

  it 'should snapshot environment-scoped license counts' do
    account     = create(:account)
    environment = create(:environment, account:)

    create_list(:license, 2, account:, environment:)
    create_list(:license, 3, account:, environment: nil)

    described_class.perform_async(account.id)

    env_spark = LicenseSpark.for_account(account)
                            .for_environment(environment)
                            .where(created_date: Date.today)
                            .first

    global_spark = LicenseSpark.for_account(account)
                               .for_environment(nil)
                               .where(created_date: Date.today)
                               .first

    expect(env_spark&.count).to eq(2)
    expect(global_spark&.count).to eq(3)
  end
end
