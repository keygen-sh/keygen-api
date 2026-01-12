# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

require_dependency Rails.root / 'lib' / 'read_your_own_writes'

describe ReadYourOwnWrites do
  after { ReadYourOwnWrites.reset_configuration! }

  describe '.configure' do
    it 'should yield configuration' do
      described_class.configure do |config|
        config.ignored_request_paths = [/test/]
        config.redis_key_prefix = 'custom'
      end

      expect(described_class.configuration.ignored_request_paths).to eq([/test/])
      expect(described_class.configuration.redis_key_prefix).to eq('custom')
    end

    it 'should sync delay from Rails database_selector config via load hook' do
      expect(described_class.configuration.database_selector_delay).to eq(2.seconds)
    end

    it 'should default redis_ttl to delay * 2' do
      expect(described_class.configuration.redis_ttl).to eq(4.seconds)
    end

    it 'should allow overriding redis_ttl' do
      described_class.configure do |config|
        config.redis_ttl = 30.seconds
      end

      expect(described_class.configuration.redis_ttl).to eq(30.seconds)
    end
  end

  describe '.reset_configuration!' do
    it 'should reset to defaults' do
      described_class.configure do |config|
        config.ignored_request_paths = [/test/]
      end

      described_class.reset_configuration!

      expect(described_class.configuration.ignored_request_paths).to eq([])
    end
  end

  describe ReadYourOwnWrites::RequestPath do
    describe '#matches?' do
      it 'should match when one scope is prefix of another' do
        path1 = described_class.new(segments: ['/accounts/test/licenses'])
        path2 = described_class.new(segments: ['/accounts/test/licenses/abc'])

        expect(path1.matches?(path2)).to be(true)
        expect(path2.matches?(path1)).to be(true)
      end

      it 'should match when segments share common scope' do
        path1 = described_class.new(segments: ['/accounts/test', '/accounts/test/licenses'])
        path2 = described_class.new(segments: ['/accounts/test', '/accounts/test/users'])

        expect(path1.matches?(path2)).to be(true)
      end

      it 'should not match sibling paths' do
        path1 = described_class.new(segments: ['/accounts/test/licenses'])
        path2 = described_class.new(segments: ['/accounts/test/users'])

        expect(path1.matches?(path2)).to be(false)
      end

      it 'should not match when segments have no common scope' do
        path1 = described_class.new(segments: ['/accounts/test'])
        path2 = described_class.new(segments: ['/accounts/other'])

        expect(path1.matches?(path2)).to be(false)
      end

      it 'should not match partial segment prefixes' do
        path1 = described_class.new(segments: ['/accounts/test'])
        path2 = described_class.new(segments: ['/accounts/testing'])

        expect(path1.matches?(path2)).to be(false)
      end

      it 'should match everything when either segments is nil' do
        path1 = described_class.new(segments: nil)
        path2 = described_class.new(segments: ['/accounts/test'])

        expect(path1.matches?(path2)).to be(true)
        expect(path2.matches?(path1)).to be(true)
      end

      it 'should match when both segments are nil' do
        path1 = described_class.new(segments: nil)
        path2 = described_class.new(segments: nil)

        expect(path1.matches?(path2)).to be(true)
      end

      it 'should match exact scope' do
        path1 = described_class.new(segments: ['/accounts/test/licenses/abc'])
        path2 = described_class.new(segments: ['/accounts/test/licenses/abc'])

        expect(path1.matches?(path2)).to be(true)
      end
    end

    describe '#to_s' do
      it 'should return the last scope in segments' do
        path = described_class.new(segments: ['/accounts/test', '/accounts/test/licenses'])

        expect(path.to_s).to eq('/accounts/test/licenses')
      end

      it 'should return / for nil segments' do
        path = described_class.new(segments: nil)

        expect(path.to_s).to eq('/')
      end

      it 'should return / for empty segments' do
        path = described_class.new(segments: [])

        expect(path.to_s).to eq('/')
      end
    end
  end

  describe '.reading_own_writes?' do
    def build_request(path:, authorization: 'Bearer test-token', remote_ip: '192.168.1.1', env: {})
      instance_double(ActionDispatch::Request, path:, authorization:, remote_ip:, env:)
    end

    it 'should return false when no recent writes exist' do
      request = build_request(path: '/v1/accounts/test/licenses')

      expect(described_class.reading_own_writes?(request)).to be(false)
    end

    it 'should return true when recent write exists' do
      write_request = build_request(path: '/v1/accounts/test/licenses/abc')
      write_context = ReadYourOwnWrites::Resolver::Context.new(write_request)
      write_context.update_last_write_timestamp

      read_request = build_request(path: '/v1/accounts/test/licenses')

      expect(described_class.reading_own_writes?(read_request)).to be(true)
    end

    it 'should return true for any path after a write (default behavior)' do
      write_request = build_request(path: '/v1/accounts/test/licenses/abc')
      write_context = ReadYourOwnWrites::Resolver::Context.new(write_request)
      write_context.update_last_write_timestamp

      read_request = build_request(path: '/v1/accounts/test/users')

      expect(described_class.reading_own_writes?(read_request)).to be(true)
    end

    it 'should return false when write is older than delay' do
      write_request = build_request(path: '/v1/accounts/test/licenses/abc')
      write_context = ReadYourOwnWrites::Resolver::Context.new(write_request)
      write_context.update_last_write_timestamp

      read_request = build_request(path: '/v1/accounts/test/licenses')

      travel 5.seconds do
        expect(described_class.reading_own_writes?(read_request)).to be(false)
      end
    end
  end

  describe ReadYourOwnWrites::Resolver::Context do
    let(:redis) { Rails.cache.redis }

    def build_request(path:, authorization: 'Bearer test-token', remote_ip: '192.168.1.1', env: {})
      instance_double(ActionDispatch::Request, path:, authorization:, remote_ip:, env:)
    end

    describe '.call' do
      it 'should create a new instance from a request' do
        request = build_request(path: '/v1/accounts/test/licenses')
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
      it 'should return epoch when no writes exist' do
        request = build_request(path: '/v1/accounts/test/licenses')
        context = described_class.new(request)

        expect(context.last_write_timestamp).to eq(Time.at(0))
      end

      it 'should return timestamp after a write' do
        write_request = build_request(path: '/v1/accounts/test/licenses/abc')
        write_context = described_class.new(write_request)
        write_context.update_last_write_timestamp

        read_request = build_request(path: '/v1/accounts/test/licenses')
        read_context = described_class.new(read_request)

        expect(read_context.last_write_timestamp).to be_within(1.second).of(Time.now)
      end

      it 'should return timestamp for any path after a write (default behavior)' do
        write_request = build_request(path: '/v1/accounts/test/licenses/abc')
        write_context = described_class.new(write_request)
        write_context.update_last_write_timestamp

        read_request = build_request(path: '/v1/accounts/test/users')
        read_context = described_class.new(read_request)

        expect(read_context.last_write_timestamp).to be_within(1.second).of(Time.now)
      end
    end

    describe '#update_last_write_timestamp' do
      it 'should store each scope in the path segments in redis sorted set' do
        ReadYourOwnWrites.configure do |config|
          config.request_path_resolver = ->(request) {
            ReadYourOwnWrites::RequestPath.new(segments: ['/accounts/test', '/accounts/test/licenses'])
          }
        end

        request = build_request(path: '/v1/accounts/test/licenses')
        context = described_class.new(request)

        freeze_time do
          context.update_last_write_timestamp

          members = redis.then { it.zrange("ryow:#{context.send(:client_id)}", 0, -1, with_scores: true) }

          expect(members.length).to eq(2)
          expect(members.map(&:first)).to contain_exactly('/accounts/test', '/accounts/test/licenses')
        end
      end

      it 'should set TTL on redis key' do
        request = build_request(path: '/v1/accounts/test/licenses')
        context = described_class.new(request)

        context.update_last_write_timestamp

        ttl = redis.then { it.ttl("ryow:#{context.send(:client_id)}") }
        expected_ttl = ReadYourOwnWrites.configuration.redis_ttl.to_i

        expect(ttl).to be_between(1, expected_ttl)
      end

      it 'should store scopes from multiple writes' do
        request1 = build_request(path: '/v1/accounts/test/licenses/abc')
        context1 = described_class.new(request1)
        context1.update_last_write_timestamp

        request2 = build_request(path: '/v1/accounts/test/users/xyz')
        context2 = described_class.new(request2)
        context2.update_last_write_timestamp

        members = redis.then { it.zrange("ryow:#{context1.send(:client_id)}", 0, -1) }

        expect(members).to contain_exactly(
          '/v1/accounts/test/licenses/abc',
          '/v1/accounts/test/users/xyz',
        )
      end
    end

    describe '#save' do
      it 'should be a no-op' do
        request = build_request(path: '/v1/accounts/test/licenses')
        context = described_class.new(request)
        response = instance_double(ActionDispatch::Response)

        expect { context.save(response) }.not_to raise_error
      end
    end

    describe 'path matching (opt-in)' do
      before do
        # Opt into path-based matching
        ReadYourOwnWrites.configure do |config|
          config.request_path_resolver = ->(request) {
            path = request.path.chomp('/').split('?').first
            ReadYourOwnWrites::RequestPath.new(segments: [path])
          }
        end

        # Simulate a write to /v1/accounts/test/licenses/bar
        write_request = build_request(path: '/v1/accounts/test/licenses/bar')
        write_context = described_class.new(write_request)
        write_context.update_last_write_timestamp
      end

      it 'should match read to parent path (listing)' do
        # GET /licenses should see writes to /licenses/bar
        read_request = build_request(path: '/v1/accounts/test/licenses')
        read_context = described_class.new(read_request)

        expect(read_context.last_write_timestamp).to be_within(1.second).of(Time.now)
      end

      it 'should match read to exact path' do
        # GET /licenses/bar should see writes to /licenses/bar
        read_request = build_request(path: '/v1/accounts/test/licenses/bar')
        read_context = described_class.new(read_request)

        expect(read_context.last_write_timestamp).to be_within(1.second).of(Time.now)
      end

      it 'should match read to child path (actions)' do
        # POST /licenses/bar/actions/validate should see writes to /licenses/bar
        read_request = build_request(path: '/v1/accounts/test/licenses/bar/actions/check-in')
        read_context = described_class.new(read_request)

        expect(read_context.last_write_timestamp).to be_within(1.second).of(Time.now)
      end

      it 'should not match read to sibling path' do
        # GET /users should NOT see writes to /licenses/bar
        read_request = build_request(path: '/v1/accounts/test/users')
        read_context = described_class.new(read_request)

        expect(read_context.last_write_timestamp).to eq(Time.at(0))
      end

      it 'should not match read to different account with custom client_identifier' do
        ReadYourOwnWrites.configure do |config|
          config.client_identifier = ->(request) {
            account_id = request.path[/^\/v\d+\/accounts\/([^\/]+)\//, 1]

            ReadYourOwnWrites::ClientIdentity.new(id: [account_id, request.authorization, request.remote_ip].join(':'))
          }
        end

        # Write to account "test"
        write_request = build_request(path: '/v1/accounts/test/licenses/bar')
        write_context = described_class.new(write_request)
        write_context.update_last_write_timestamp

        # GET /accounts/other/licenses should NOT see writes to /accounts/test/licenses/bar
        # because they have different client IDs (different account)
        read_request = build_request(path: '/v1/accounts/other/licenses')
        read_context = described_class.new(read_request)

        expect(read_context.last_write_timestamp).to eq(Time.at(0))
      end
    end

    describe 'replica-only patterns' do
      before do
        ReadYourOwnWrites.configure do |config|
          config.ignored_request_paths = [
            /\/actions\/validate-key\z/,
            /\/actions\/search\z/,
          ]
        end

        # Simulate a write
        write_request = build_request(path: '/v1/accounts/test/licenses/bar')
        write_context = described_class.new(write_request)
        write_context.update_last_write_timestamp
      end

      it 'should always use replica for configured patterns' do
        read_request = build_request(path: '/v1/accounts/test/licenses/actions/validate-key')
        read_context = described_class.new(read_request)

        expect(read_context.last_write_timestamp).to eq(Time.at(0))
      end

      it 'should not affect non-matching patterns' do
        read_request = build_request(path: '/v1/accounts/test/licenses/bar/actions/check-in')
        read_context = described_class.new(read_request)

        expect(read_context.last_write_timestamp).to be_within(1.second).of(Time.now)
      end
    end

    describe 'force replica via request env' do
      before do
        # Simulate a write
        write_request = build_request(path: '/v1/accounts/test/licenses/bar')
        write_context = described_class.new(write_request)
        write_context.update_last_write_timestamp
      end

      it 'should use replica when SKIP_RYOW_KEY is set' do
        request = instance_double(
          ActionDispatch::Request,
          path: '/v1/accounts/test/licenses/bar',
          authorization: 'Bearer test-token',
          remote_ip: '192.168.1.1',
          env: { ReadYourOwnWrites::SKIP_RYOW_KEY => true },
        )
        context = described_class.new(request)

        expect(context.last_write_timestamp).to eq(Time.at(0))
      end

      it 'should use primary when SKIP_RYOW_KEY is not set' do
        request = instance_double(
          ActionDispatch::Request,
          path: '/v1/accounts/test/licenses/bar',
          authorization: 'Bearer test-token',
          remote_ip: '192.168.1.1',
          env: {},
        )
        context = described_class.new(request)

        expect(context.last_write_timestamp).to be_within(1.second).of(Time.now)
      end
    end

    describe 'client identification' do
      it 'should generate different client IDs for different tokens' do
        context1 = described_class.new(build_request(path: '/test', authorization: 'Bearer token-1'))
        context2 = described_class.new(build_request(path: '/test', authorization: 'Bearer token-2'))

        expect(context1.send(:client_id)).not_to eq(context2.send(:client_id))
      end

      it 'should generate different client IDs for different IPs' do
        context1 = described_class.new(build_request(path: '/test', remote_ip: '192.168.1.1'))
        context2 = described_class.new(build_request(path: '/test', remote_ip: '192.168.1.2'))

        expect(context1.send(:client_id)).not_to eq(context2.send(:client_id))
      end

      it 'should generate same client ID for same request attributes' do
        context1 = described_class.new(build_request(path: '/foo'))
        context2 = described_class.new(build_request(path: '/bar'))

        expect(context1.send(:client_id)).to eq(context2.send(:client_id))
      end

      it 'should generate SHA256 digest as client ID' do
        context = described_class.new(build_request(path: '/test'))

        expect(context.send(:client_id)).to be_a(String)
        expect(context.send(:client_id)).to start_with('client:')
        expect(context.send(:client_id).length).to eq('client:'.size + Digest::SHA2.new.block_length)
      end

      it 'should use custom client_identifier when configured' do
        ReadYourOwnWrites.configure do |config|
          config.client_identifier = ->(request) {
            account_id = request.path[/^\/accounts\/([^\/]+)/, 1]

            ReadYourOwnWrites::ClientIdentity.new(id: [account_id, request.remote_ip].join(':'))
          }
        end

        context1 = described_class.new(build_request(path: '/accounts/test/foo', remote_ip: '1.1.1.1'))
        context2 = described_class.new(build_request(path: '/accounts/test/bar', remote_ip: '1.1.1.1'))
        context3 = described_class.new(build_request(path: '/accounts/other/foo', remote_ip: '1.1.1.1'))

        # Same account + IP should produce same client ID
        expect(context1.send(:client_id)).to eq(context2.send(:client_id))
        # Different account should produce different client ID
        expect(context1.send(:client_id)).not_to eq(context3.send(:client_id))
      end

      it 'should raise TypeError when client_identifier returns wrong type' do
        ReadYourOwnWrites.configure do |config|
          config.client_identifier = ->(request) { [request.authorization, request.remote_ip] }
        end

        context = described_class.new(build_request(path: '/test'))

        expect { context.send(:client_id) }.to raise_error(TypeError, /must return a ClientIdentity/)
      end
    end

    describe 'request path resolution' do
      it 'should use custom request_path_resolver when configured' do
        ReadYourOwnWrites.configure do |config|
          config.request_path_resolver = ->(request) {
            ReadYourOwnWrites::RequestPath.new(segments: ['/custom/scope'])
          }
        end

        # Write with custom resolver
        write_request = build_request(path: '/anything')
        write_context = described_class.new(write_request)
        write_context.update_last_write_timestamp

        # Read with same custom scope should match
        read_request = build_request(path: '/different/path')
        read_context = described_class.new(read_request)

        expect(read_context.last_write_timestamp).to be_within(1.second).of(Time.now)
      end

      it 'should match when segments share common scope' do
        ReadYourOwnWrites.configure do |config|
          config.request_path_resolver = ->(request) {
            if request.path.include?('licenses')
              ReadYourOwnWrites::RequestPath.new(segments: ['/accounts/test', '/accounts/test/licenses'])
            else
              ReadYourOwnWrites::RequestPath.new(segments: ['/accounts/test', '/accounts/test/users'])
            end
          }
        end

        # Write to licenses
        write_request = build_request(path: '/v1/accounts/test/licenses/abc')
        write_context = described_class.new(write_request)
        write_context.update_last_write_timestamp

        # Read from users should match (shares /accounts/test scope)
        read_request = build_request(path: '/v1/accounts/test/users')
        read_context = described_class.new(read_request)

        expect(read_context.last_write_timestamp).to be_within(1.second).of(Time.now)
      end

      it 'should not match when segments have no common scope' do
        ReadYourOwnWrites.configure do |config|
          config.request_path_resolver = ->(request) {
            account = request.path[/accounts\/([^\/]+)/, 1]
            ReadYourOwnWrites::RequestPath.new(segments: ["/accounts/#{account}"])
          }
        end

        # Write to account "test"
        write_request = build_request(path: '/v1/accounts/test/licenses')
        write_context = described_class.new(write_request)
        write_context.update_last_write_timestamp

        # Read from account "other" should not match
        read_request = build_request(path: '/v1/accounts/other/licenses')
        read_context = described_class.new(read_request)

        expect(read_context.last_write_timestamp).to eq(Time.at(0))
      end

      it 'should match everything when stack is nil (opt-out)' do
        ReadYourOwnWrites.configure do |config|
          config.request_path_resolver = ->(request) {
            ReadYourOwnWrites::RequestPath.new(segments: nil)
          }
        end

        # Write to any path
        write_request = build_request(path: '/v1/accounts/test/licenses')
        write_context = described_class.new(write_request)
        write_context.update_last_write_timestamp

        # Read from completely different path should still match
        read_request = build_request(path: '/v1/completely/different/path')
        read_context = described_class.new(read_request)

        expect(read_context.last_write_timestamp).to be_within(1.second).of(Time.now)
      end

      it 'should raise TypeError when request_path_resolver returns wrong type' do
        ReadYourOwnWrites.configure do |config|
          config.request_path_resolver = ->(request) { request.path }
        end

        context = described_class.new(build_request(path: '/test'))

        expect { context.send(:request_path) }.to raise_error(TypeError, /must return a RequestPath/)
      end
    end

    describe 'redis failure handling' do
      it 'should return epoch on redis connection error' do
        request = build_request(path: '/v1/accounts/test/licenses')
        context = described_class.new(request)

        allow(Rails.cache).to receive(:redis).and_raise(Errno::ECONNREFUSED)

        expect(context.last_write_timestamp).to eq(Time.at(0))
      end

      it 'should not raise on redis error during update' do
        request = build_request(path: '/v1/accounts/test/licenses')
        context = described_class.new(request)

        allow(Rails.cache).to receive(:redis).and_raise(Redis::BaseError)

        expect { context.update_last_write_timestamp }.not_to raise_error
      end
    end
  end

  describe ReadYourOwnWrites::Controller do
    def build_request(path:, authorization: 'Bearer test-token', remote_ip: '192.168.1.1', env: {})
      instance_double(ActionDispatch::Request, path:, authorization:, remote_ip:, env:)
    end

    let(:test_controller_class) do
      Class.new(ActionController::API) do
        include ReadYourOwnWrites::Controller

        def request
          @request
        end

        def request=(req)
          @request = req
        end

        def index
          { role: ActiveRecord::Base.current_role }
        end
      end
    end

    let(:controller) { test_controller_class.new }

    describe '.use_primary' do
      it 'should add around_action for primary connection' do
        test_controller_class.use_primary only: :index

        expect(test_controller_class._process_action_callbacks.map(&:filter)).to include(:with_primary_connection)
      end
    end

    describe '.use_read_replica' do
      it 'should add around_action for replica connection' do
        test_controller_class.use_read_replica only: :index

        expect(test_controller_class._process_action_callbacks.map(&:filter)).to include(:with_read_replica_connection)
      end
    end

    describe '.prefer_read_replica' do
      it 'should add around_action for conditional replica connection' do
        test_controller_class.prefer_read_replica only: :index

        expect(test_controller_class._process_action_callbacks.map(&:filter)).to include(:with_read_replica_connection_unless_reading_own_writes)
      end
    end

    describe '#with_primary_connection' do
      it 'should execute block with writing role' do
        role_during_block = nil

        controller.with_primary_connection do
          role_during_block = ActiveRecord::Base.current_role
        end

        expect(role_during_block).to eq(:writing)
      end

      it 'should restore role after block' do
        ActiveRecord::Base.connected_to(role: :reading) do
          role_was = ActiveRecord::Base.current_role

          controller.with_primary_connection do
            # nothing
          end

          expect(ActiveRecord::Base.current_role).to eq(role_was)
        end
      end
    end

    describe '#with_read_replica_connection' do
      it 'should execute block with reading role' do
        role_during_block = nil

        controller.with_read_replica_connection do
          role_during_block = ActiveRecord::Base.current_role
        end

        expect(role_during_block).to eq(:reading)
      end

      it 'should restore role after block' do
        ActiveRecord::Base.connected_to(role: :writing) do
          role_was = ActiveRecord::Base.current_role

          controller.with_read_replica_connection do
            # nada
          end

          expect(ActiveRecord::Base.current_role).to eq(role_was)
        end
      end
    end

    describe '#with_read_replica_connection_unless_reading_own_writes' do
      context 'when no recent writes exist' do
        before do
          controller.request = build_request(path: '/v1/accounts/test/licenses')
        end

        it 'should execute block with reading role' do
          role_during_block = nil

          controller.with_read_replica_connection_unless_reading_own_writes do
            role_during_block = ActiveRecord::Base.current_role
          end

          expect(role_during_block).to eq(:reading)
        end
      end

      context 'when recent write exists' do
        before do
          write_request = build_request(path: '/v1/accounts/test/licenses/abc')
          write_context = ReadYourOwnWrites::Resolver::Context.new(write_request)
          write_context.update_last_write_timestamp

          controller.request = build_request(path: '/v1/accounts/test/licenses')
        end

        it 'should not change role (respects RYOW)' do
          original_role = ActiveRecord::Base.current_role
          role_during_block = nil

          controller.with_read_replica_connection_unless_reading_own_writes do
            role_during_block = ActiveRecord::Base.current_role
          end

          expect(role_during_block).to eq(original_role)
        end
      end

      context 'when write is older than delay' do
        before do
          write_request = build_request(path: '/v1/accounts/test/licenses/abc')
          write_context = ReadYourOwnWrites::Resolver::Context.new(write_request)
          write_context.update_last_write_timestamp

          controller.request = build_request(path: '/v1/accounts/test/licenses')
        end

        it 'should execute block with reading role' do
          role_during_block = nil

          travel 5.seconds do
            controller.with_read_replica_connection_unless_reading_own_writes do
              role_during_block = ActiveRecord::Base.current_role
            end
          end

          expect(role_during_block).to eq(:reading)
        end
      end
    end
  end
end
