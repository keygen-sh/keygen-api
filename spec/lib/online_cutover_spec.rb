# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

require_dependency Rails.root / 'lib' / 'online_cutover'

describe OnlineCutover do
  let(:redis) { Rails.cache.redis }

  after do
    OnlineCutover.state.reset!
  end

  describe '.configure' do
    around do |example|
      config_was = described_class.instance_variable_get(:@configuration)
      described_class.instance_variable_set(:@configuration, nil)

      example.run
    ensure
      described_class.instance_variable_set(:@configuration, config_was)
    end

    it 'should yield configuration' do
      described_class.configure do |config|
        config.quiesce_timeout = 60.seconds
        config.state_ttl = 2.hours
      end

      expect(described_class.configuration.quiesce_timeout).to eq(60.seconds)
      expect(described_class.configuration.state_ttl).to eq(2.hours)
    end

    it 'should have sensible defaults' do
      expect(described_class.configuration.quiesce_timeout).to eq(30.seconds)
      expect(described_class.configuration.state_ttl).to eq(1.hour)
    end

    it 'should support proc for debug' do
      described_class.configure { it.debug = -> { true } }

      expect(described_class.configuration.debug?).to be(true)
    end
  end

  describe 'phase transitions' do
    it 'should default to normal phase' do
      expect(described_class.current_phase).to eq(OnlineCutover::PHASE_NORMAL)
    end

    it 'should transition to quiescing' do
      described_class.set_phase!(OnlineCutover::PHASE_QUIESCING)

      expect(described_class.current_phase).to eq(OnlineCutover::PHASE_QUIESCING)
      expect(described_class.current_phase.quiescing?).to be(true)
      expect(described_class.current_phase.normal?).to be(false)
    end

    it 'should transition back to normal' do
      described_class.set_phase!(OnlineCutover::PHASE_QUIESCING)
      described_class.set_phase!(OnlineCutover::PHASE_NORMAL)

      expect(described_class.current_phase).to eq(OnlineCutover::PHASE_NORMAL)
      expect(described_class.current_phase.normal?).to be(true)
    end

    it 'should persist to Redis' do
      described_class.set_phase!(OnlineCutover::PHASE_QUIESCING)

      raw = redis.then { it.get(OnlineCutover::REDIS_STATE_KEY) }
      state = JSON.parse(raw, symbolize_names: true)

      expect(state[:phase]).to eq(OnlineCutover::PHASE_QUIESCING)
    end

    it 'should reject invalid phases' do
      expect { described_class.set_phase!('invalid') }.to raise_error(OnlineCutover::InvalidPhaseError)
    end
  end

  describe 'routing transitions' do
    it 'should default to current routing' do
      expect(described_class.current_routing).to eq(OnlineCutover::ROUTING_NORMAL)
    end

    it 'should transition to promoted' do
      described_class.set_routing!(OnlineCutover::ROUTING_PROMOTED)

      expect(described_class.current_routing).to eq(OnlineCutover::ROUTING_PROMOTED)
      expect(described_class.current_routing.promoted?).to be(true)
      expect(described_class.current_routing.normal?).to be(false)
    end

    it 'should transition to aborted' do
      described_class.set_routing!(OnlineCutover::ROUTING_ABORTED)

      expect(described_class.current_routing).to eq(OnlineCutover::ROUTING_ABORTED)
      expect(described_class.current_routing.aborted?).to be(true)
    end

    it 'should persist to Redis' do
      described_class.set_routing!(OnlineCutover::ROUTING_PROMOTED)

      raw = redis.then { it.get(OnlineCutover::REDIS_STATE_KEY) }
      state = JSON.parse(raw, symbolize_names: true)

      expect(state[:routing]).to eq(OnlineCutover::ROUTING_PROMOTED)
    end

    it 'should reject invalid routings' do
      expect { described_class.set_routing!('invalid') }.to raise_error(OnlineCutover::InvalidRoutingError)
    end
  end

  describe '.started?' do
    it 'should return false when in nominal state' do
      expect(described_class.started?).to be(false)
    end

    it 'should return true when quiescing' do
      described_class.set_phase!(OnlineCutover::PHASE_QUIESCING)

      expect(described_class.started?).to be(true)
    end

    it 'should return true when promoted' do
      described_class.set_routing!(OnlineCutover::ROUTING_PROMOTED)

      expect(described_class.started?).to be(true)
    end

    it 'should return true when aborted' do
      described_class.set_routing!(OnlineCutover::ROUTING_ABORTED)

      expect(described_class.started?).to be(true)
    end
  end

  describe '.status' do
    it 'should return current state' do
      status = described_class.status

      expect(status[:phase]).to eq(OnlineCutover::PHASE_NORMAL)
      expect(status[:routing]).to eq(OnlineCutover::ROUTING_NORMAL)
      expect(status[:started]).to be(false)
      expect(status[:quiesce_timeout]).to eq(30.seconds)
    end
  end

  describe OnlineCutover::State do
    describe '#sync_from_redis!' do
      it 'should sync phase from Redis' do
        redis.then do |conn|
          conn.set(OnlineCutover::REDIS_STATE_KEY, JSON.generate(phase: OnlineCutover::PHASE_QUIESCING, routing: OnlineCutover::ROUTING_NORMAL))
        end

        described_class.instance.sync_from_redis!

        expect(OnlineCutover.current_phase).to eq(OnlineCutover::PHASE_QUIESCING)
      end

      it 'should sync routing from Redis' do
        redis.then do |conn|
          conn.set(OnlineCutover::REDIS_STATE_KEY, JSON.generate(phase: OnlineCutover::PHASE_NORMAL, routing: OnlineCutover::ROUTING_PROMOTED))
        end

        described_class.instance.sync_from_redis!

        expect(OnlineCutover.current_routing).to eq(OnlineCutover::ROUTING_PROMOTED)
      end

      it 'should handle missing key gracefully' do
        redis.then { it.del(OnlineCutover::REDIS_STATE_KEY) }

        described_class.instance.sync_from_redis!

        expect(OnlineCutover.current_phase).to eq(OnlineCutover::PHASE_NORMAL)
        expect(OnlineCutover.current_routing).to eq(OnlineCutover::ROUTING_NORMAL)
      end
    end

    describe '#update_local_phase' do
      it 'should update local phase without touching Redis' do
        described_class.instance.update_local_phase(OnlineCutover::PHASE_QUIESCING)

        expect(OnlineCutover.current_phase).to eq(OnlineCutover::PHASE_QUIESCING)

        # Redis should still have default
        raw = redis.then { it.get(OnlineCutover::REDIS_STATE_KEY) }
        expect(raw).to be_nil
      end
    end

    describe '#update_local_routing' do
      it 'should update local routing without touching Redis' do
        described_class.instance.update_local_routing(OnlineCutover::ROUTING_PROMOTED)

        expect(OnlineCutover.current_routing).to eq(OnlineCutover::ROUTING_PROMOTED)

        # Redis should still have default
        raw = redis.then { it.get(OnlineCutover::REDIS_STATE_KEY) }
        expect(raw).to be_nil
      end
    end
  end

  describe OnlineCutover::Middleware do
    let(:app) { ->(env) { [200, { 'Content-Type' => 'text/plain' }, ['OK']] } }
    let(:middleware) { described_class.new(app) }
    let(:env) { Rack::MockRequest.env_for('/test') }

    context 'when not quiescing' do
      it 'should pass through normally' do
        status, headers, body = middleware.call(env)

        expect(status).to eq(200)
        expect(headers).to include('Content-Type' => 'text/plain')
        expect(body).to eq(['OK'])
      end
    end

    context 'when quiescing' do
      before do
        OnlineCutover.set_phase!(OnlineCutover::PHASE_QUIESCING)
      end

      it 'should block until resumed' do
        Thread.new do
          sleep 0.1 # resume after a brief delay

          OnlineCutover.set_phase!(OnlineCutover::PHASE_NORMAL)
        end

        status, headers, body = middleware.call(env)

        expect(status).to eq(200)
      end

      context 'when timeout expires' do
        around do |example|
          timeout_was, OnlineCutover.configuration.quiesce_timeout = OnlineCutover.configuration.quiesce_timeout, 0.1.seconds

          example.run
        ensure
          OnlineCutover.configuration.quiesce_timeout = timeout_was
        end

        it 'should return 503' do
          status, headers, body = middleware.call(env)

          expect(status).to eq(503)
          expect(headers).to include('Content-Type' => 'text/plain', 'Retry-After' => '5')
          expect(body).to eq(['Service Unavailable'])
        end
      end
    end

    context 'with shard routing' do
      let(:app) { ->(env) { [200, {}, [ActiveRecord::Base.current_shard.to_s]] } }

      context 'when routing is default' do
        it 'should use current shard' do
          status, headers, body = middleware.call(env)

          expect(body.first).to eq('normal')
        end
      end

      context 'when routing is current' do
        before do
          OnlineCutover.set_routing!(OnlineCutover::ROUTING_NORMAL)
        end

        it 'should use current shard' do
          status, headers, body = middleware.call(env)

          expect(body.first).to eq(OnlineCutover::ROUTING_NORMAL)
        end
      end

      context 'when routing is promoted' do
        before do
          OnlineCutover.set_routing!(OnlineCutover::ROUTING_PROMOTED)
        end

        it 'should use promoted shard' do
          status, headers, body = middleware.call(env)

          expect(body.first).to eq(OnlineCutover::ROUTING_PROMOTED)
        end
      end

      context 'when routing is aborted' do
        before do
          OnlineCutover.set_routing!(OnlineCutover::ROUTING_ABORTED)
        end

        it 'should use aborted shard' do
          status, headers, body = middleware.call(env)

          expect(body.first).to eq(OnlineCutover::ROUTING_ABORTED)
        end
      end
    end
  end

  describe OnlineCutover::SidekiqMiddleware do
    let(:middleware) { described_class.new }
    let(:worker) { double('worker') }
    let(:job) { {} }
    let(:queue) { 'default' }

    context 'when not quiescing' do
      it 'should yield to the block' do
        yielded = false

        middleware.call(worker, job, queue) { yielded = true }

        expect(yielded).to be(true)
      end
    end

    context 'when quiescing' do
      before do
        OnlineCutover.set_phase!(OnlineCutover::PHASE_QUIESCING)
      end

      it 'should block until resumed' do
        Thread.new do
          sleep 0.1
          OnlineCutover.set_phase!(OnlineCutover::PHASE_NORMAL)
        end

        yielded = false
        middleware.call(worker, job, queue) { yielded = true }

        expect(yielded).to be(true)
      end

      context 'when timeout expires' do
        around do |example|
          config_was = OnlineCutover.configuration.quiesce_timeout
          OnlineCutover.configuration.quiesce_timeout = 0.1.seconds

          example.run
        ensure
          OnlineCutover.configuration.quiesce_timeout = config_was
        end

        it 'should raise' do
          expect {
            middleware.call(worker, job, queue) { }
          }.to raise_error(OnlineCutover::QuiesceTimeoutError)
        end
      end
    end

    context 'when routing is normal' do
      before do
        OnlineCutover.set_routing!(OnlineCutover::ROUTING_NORMAL)
      end

      it 'should use normal shard' do
        shard = nil

        middleware.call(worker, job, queue) { shard = ActiveRecord::Base.current_shard }

        expect(shard).to eq(OnlineCutover::ROUTING_NORMAL)
      end
    end

    context 'when routing is promoted' do
      before do
        OnlineCutover.set_routing!(OnlineCutover::ROUTING_PROMOTED)
      end

      it 'should use promoted shard' do
        shard = nil

        middleware.call(worker, job, queue) { shard = ActiveRecord::Base.current_shard }

        expect(shard).to eq(OnlineCutover::ROUTING_PROMOTED)
      end
    end

    context 'when routing is aborted' do
      before do
        OnlineCutover.set_routing!(OnlineCutover::ROUTING_ABORTED)
      end

      it 'should use aborted shard' do
        shard = nil

        middleware.call(worker, job, queue) { shard = ActiveRecord::Base.current_shard }

        expect(shard).to eq(OnlineCutover::ROUTING_ABORTED)
      end
    end
  end

  describe '.current_shard' do
    it 'should return current shard by default' do
      expect(described_class.current_shard).to eq(OnlineCutover::SHARD_NORMAL)
    end

    it 'should return promoted shard when promoted' do
      OnlineCutover.set_routing!(OnlineCutover::ROUTING_PROMOTED)

      expect(described_class.current_shard).to eq(OnlineCutover::SHARD_PROMOTED)
    end

    it 'should return aborted shard when aborted' do
      OnlineCutover.set_routing!(OnlineCutover::ROUTING_ABORTED)

      expect(described_class.current_shard).to eq(OnlineCutover::SHARD_ABORTED)
    end
  end

  describe OnlineCutover::Subscriber do
    describe '#start' do
      it 'should sync from redis' do
        redis.then do |conn|
          conn.set(OnlineCutover::REDIS_STATE_KEY, JSON.generate(phase: OnlineCutover::PHASE_QUIESCING, routing: OnlineCutover::ROUTING_NORMAL))
        end

        described_class.instance.start

        expect(OnlineCutover.current_phase).to eq(OnlineCutover::PHASE_QUIESCING)
      ensure
        described_class.instance.stop
      end

      it 'should be running after start' do
        described_class.instance.start

        expect(described_class.instance.running?).to be(true)
      ensure
        described_class.instance.stop
      end
    end

    describe '#stop' do
      it 'should stop the subscriber' do
        described_class.instance.start
        described_class.instance.stop

        expect(described_class.instance.running?).to be(false)
      end
    end
  end
end
