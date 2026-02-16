# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Analytics::Usage do
  let(:account) { create(:account) }

  before { Sidekiq::Testing.inline! }
  after  { Sidekiq::Testing.fake! }

  describe '.new', :only_clickhouse do
    it 'returns request counts by date' do
      create_list(:request_log, 3, account:, created_at: 2.days.ago)
      create_list(:request_log, 2, account:, created_at: 1.day.ago)

      two_days_ago = 2.days.ago.to_date
      one_day_ago  = 1.day.ago.to_date

      usage = described_class.new(
        account:,
        start_date: 3.days.ago.to_date,
        end_date: Date.current,
      )

      expect(usage).to be_valid
      expect(usage.buckets).to satisfy do |buckets|
        buckets in [
          *,
          Analytics::Usage::Bucket(date: ^two_days_ago, count: 3),
          Analytics::Usage::Bucket(date: ^one_day_ago, count: 2),
          *
        ]
      end
    end

    it 'includes zero counts for days with no requests' do
      create(:request_log, account:, created_at: 3.days.ago)

      three_days_ago = 3.days.ago.to_date
      two_days_ago   = 2.days.ago.to_date

      usage = described_class.new(
        account:,
        start_date: 3.days.ago.to_date,
        end_date: Date.current,
      )

      expect(usage).to be_valid
      expect(usage.buckets).to satisfy do |buckets|
        buckets in [
          Analytics::Usage::Bucket(date: ^three_days_ago, count: 1),
          Analytics::Usage::Bucket(date: ^two_days_ago, count: 0),
          *
        ]
      end
    end
  end
end
