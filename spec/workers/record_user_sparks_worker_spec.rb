# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe RecordUserSparksWorker, :only_clickhouse do
  it 'should enqueue a job for each account' do
    accounts = create_list(:account, 3)

    Sidekiq::Testing.fake! do
      described_class.new.perform

      expect(RecordUserSparkWorker.jobs.size).to eq(3)
    end
  end
end
