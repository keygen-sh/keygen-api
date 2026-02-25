# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe RecordActiveLicensedUserSparkWorker, :only_clickhouse do
  before { Sidekiq::Testing.inline! }
  after  { Sidekiq::Testing.fake! }

  it 'should snapshot active licensed user counts for an account' do
    account = create(:account)

    users = create_list(:user, 3, account:)
    users.each { create(:license, account:, owner: it) }

    described_class.perform_async(account.id)

    spark = ActiveLicensedUserSpark.for_account(account)
                                   .for_environment(nil)
                                   .where(created_date: Date.today)
                                   .first

    expect(spark&.count).to eq(3)
  end

  it 'should only snapshot globally' do
    account     = create(:account)
    environment = create(:environment, account:)

    user = create(:user, account:, environment:)
    create(:license, account:, environment:, owner: user)

    described_class.perform_async(account.id)

    global_spark = ActiveLicensedUserSpark.for_account(account)
                                          .for_environment(nil)
                                          .where(created_date: Date.today)
                                          .first

    env_sparks = ActiveLicensedUserSpark.for_account(account)
                                        .for_environment(environment)
                                        .where(created_date: Date.today)

    expect(global_spark&.count).to eq(1)
    expect(env_sparks.count).to eq(0)
  end
end
