# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

require_dependency Rails.root / 'lib' / 'read_your_own_writes'

describe ReadYourOwnWrites do
  describe ReadYourOwnWrites::RedisContext do
    let(:request) do
      instance_double(
        ActionDispatch::Request,
        path: '/v1/accounts/test-account/licenses',
        authorization: 'Bearer test-token',
        remote_ip: '192.168.1.1',
      )
    end

    let(:redis) { Rails.cache.redis }

    describe '.call' do
      it 'should create a new instance from a request' do
        context = described_class.call(request)

        expect(context).to be_a(described_class)
        expect(context.request).to eq(request)
      end
    end

    describe '.convert_time_to_timestamp' do
      it 'should convert time to milliseconds since epoch' do
        time = Time.at(1704067200, 500_000) # 2024-01-01 00:00:00.500 UTC

        timestamp = described_class.convert_time_to_timestamp(time)

        expect(timestamp).to eq(1704067200500)
      end
    end

    describe '.convert_timestamp_to_time' do
      it 'should convert milliseconds since epoch to time' do
        timestamp = 1704067200500

        time = described_class.convert_timestamp_to_time(timestamp)

        expect(time.to_i).to eq(1704067200)
        expect(time.usec).to eq(500_000)
      end

      it 'should return epoch for nil timestamp' do
        time = described_class.convert_timestamp_to_time(nil)

        expect(time).to eq(Time.at(0))
      end
    end

    describe '#last_write_timestamp' do
      let(:context) { described_class.new(request) }

      it 'should return epoch when no timestamp exists' do
        expect(context.last_write_timestamp).to eq(Time.at(0))
      end

      it 'should return stored timestamp from redis' do
        expected_time = Time.now
        expected_timestamp = described_class.convert_time_to_timestamp(expected_time)

        redis.then { it.set("ryow:#{context.send(:client_id)}", expected_timestamp) }

        result = context.last_write_timestamp

        expect(result.to_i).to eq(expected_time.to_i)
      end
    end

    describe '#update_last_write_timestamp' do
      let(:context) { described_class.new(request) }

      it 'should store timestamp in redis' do
        freeze_time do
          context.update_last_write_timestamp

          stored = redis.then { it.get("ryow:#{context.send(:client_id)}") }.to_i
          expected = described_class.convert_time_to_timestamp(Time.now)

          expect(stored).to eq(expected)
        end
      end

      it 'should set TTL on redis key' do
        context.update_last_write_timestamp

        ttl = redis.then { it.ttl("ryow:#{context.send(:client_id)}") }

        expect(ttl).to be_between(1, 30)
      end
    end

    describe '#save' do
      let(:context) { described_class.new(request) }
      let(:response) { instance_double(ActionDispatch::Response) }

      it 'should be a no-op' do
        expect { context.save(response) }.not_to raise_error
      end
    end

    describe 'client identification' do
      it 'should generate different client IDs for different accounts' do
        request1 = instance_double(
          ActionDispatch::Request,
          path: '/v1/accounts/account-1/licenses',
          authorization: 'Bearer token',
          remote_ip: '192.168.1.1',
        )
        request2 = instance_double(
          ActionDispatch::Request,
          path: '/v1/accounts/account-2/licenses',
          authorization: 'Bearer token',
          remote_ip: '192.168.1.1',
        )

        context1 = described_class.new(request1)
        context2 = described_class.new(request2)

        expect(context1.send(:client_id)).not_to eq(context2.send(:client_id))
      end

      it 'should generate different client IDs for different tokens' do
        request1 = instance_double(
          ActionDispatch::Request,
          path: '/v1/accounts/test/licenses',
          authorization: 'Bearer token-1',
          remote_ip: '192.168.1.1',
        )
        request2 = instance_double(
          ActionDispatch::Request,
          path: '/v1/accounts/test/licenses',
          authorization: 'Bearer token-2',
          remote_ip: '192.168.1.1',
        )

        context1 = described_class.new(request1)
        context2 = described_class.new(request2)

        expect(context1.send(:client_id)).not_to eq(context2.send(:client_id))
      end

      it 'should generate different client IDs for different IPs' do
        request1 = instance_double(
          ActionDispatch::Request,
          path: '/v1/accounts/test/licenses',
          authorization: 'Bearer token',
          remote_ip: '192.168.1.1',
        )
        request2 = instance_double(
          ActionDispatch::Request,
          path: '/v1/accounts/test/licenses',
          authorization: 'Bearer token',
          remote_ip: '192.168.1.2',
        )

        context1 = described_class.new(request1)
        context2 = described_class.new(request2)

        expect(context1.send(:client_id)).not_to eq(context2.send(:client_id))
      end

      it 'should generate same client ID for same request attributes' do
        request1 = instance_double(
          ActionDispatch::Request,
          path: '/v1/accounts/test/licenses',
          authorization: 'Bearer token',
          remote_ip: '192.168.1.1',
        )
        request2 = instance_double(
          ActionDispatch::Request,
          path: '/v1/accounts/test/licenses',
          authorization: 'Bearer token',
          remote_ip: '192.168.1.1',
        )

        context1 = described_class.new(request1)
        context2 = described_class.new(request2)

        expect(context1.send(:client_id)).to eq(context2.send(:client_id))
      end

      it 'should extract account ID from path' do
        request = instance_double(
          ActionDispatch::Request,
          path: '/v1/accounts/my-account-slug/licenses',
          authorization: nil,
          remote_ip: '127.0.0.1',
        )

        context = described_class.new(request)
        client_id = context.send(:client_id)

        # Verify different account produces different ID
        request2 = instance_double(
          ActionDispatch::Request,
          path: '/v1/accounts/other-account/licenses',
          authorization: nil,
          remote_ip: '127.0.0.1',
        )
        context2 = described_class.new(request2)

        expect(client_id).not_to eq(context2.send(:client_id))
      end

      it 'should handle paths without account ID' do
        request = instance_double(
          ActionDispatch::Request,
          path: '/health',
          authorization: nil,
          remote_ip: '127.0.0.1',
        )

        context = described_class.new(request)

        expect { context.send(:client_id) }.not_to raise_error
        expect(context.send(:client_id)).to be_a(String)
        expect(context.send(:client_id).length).to eq(64) # SHA256 hex length
      end
    end

    describe 'redis failure handling' do
      let(:context) { described_class.new(request) }

      it 'should return epoch on redis connection error' do
        allow(Rails.cache).to receive(:redis).and_raise(Errno::ECONNREFUSED)

        expect(context.last_write_timestamp).to eq(Time.at(0))
      end

      it 'should not raise on redis error during update' do
        allow(Rails.cache).to receive(:redis).and_raise(Redis::BaseError)

        expect { context.update_last_write_timestamp }.not_to raise_error
      end
    end
  end
end
