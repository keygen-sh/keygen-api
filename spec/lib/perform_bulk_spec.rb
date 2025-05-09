# frozen_string_literal: true

require 'sidekiq/testing'
require 'sidekiq/api'
require 'temporary_tables'
require 'rails_helper'
require 'spec_helper'

require_dependency Rails.root / 'lib' / 'perform_bulk'

describe PerformBulk do
  let(:wait_queue)    { Sidekiq::Queue.new('perform_bulk:waiting') }
  let(:process_queue) { Sidekiq::Queue.new('perform_bulk:processing') }
  let(:run_queue)     { Sidekiq::Queue.new('perform_bulk:running') }

  let(:capsule) { Sidekiq::Capsule.new('perform_bulk/test', Sidekiq.default_configuration) }
  let(:config)  { capsule.config }

  after do
    [wait_queue, process_queue, run_queue].each(&:clear) # redis
    Sidekiq::Queues.clear_all # memory
  end

  describe PerformBulk::BulkFetch do
    let(:fetcher) { PerformBulk::BulkFetch }

    it 'should bulk fetch from waiting queue' do
      capsule.config[:bulk_batch_size] = 2
      capsule.queues = [wait_queue.name]

      # queue work
      Sidekiq.redis do |conn|
        conn.lpush("queue:#{wait_queue.name}", %w[foo bar baz])
      end

      expect(wait_queue.size).to eq 3

      # fetch work
      fetch = fetcher.new(capsule)
      work  = 3.times.map { fetch.retrieve_work }

      expect(wait_queue.size).to eq 0
      expect(work.size).to eq 3

      expect(work).to satisfy do |items|
        queue = "queue:#{wait_queue.name}"

        items in [
          PerformBulk::UnitOfWork(queue: ^queue, jobs: ['foo', 'bar']),
          PerformBulk::UnitOfWork(queue: ^queue, jobs: ['baz']),
          nil,
        ]
      end
    end

    it 'should bulk requeue into waiting' do
      capsule.config[:bulk_batch_size] = 2
      capsule.queues = [wait_queue.name]

      # queue work
      Sidekiq.redis do |conn|
        conn.lpush("queue:#{wait_queue.name}", %w[foo bar baz])
      end

      expect(wait_queue.size).to eq 3

      # fetch work
      fetch = fetcher.new(capsule)
      work  = 2.times.map { fetch.retrieve_work }

      expect(wait_queue.size).to eq 0
      expect(work.size).to eq 2

      # requeue work
      fetch.bulk_requeue(work)

      expect(wait_queue.size).to eq 3
    end
  end

  describe PerformBulk::UnitOfWork do
    let(:unit_of_work) { PerformBulk::UnitOfWork.new(queue: "queue:#{wait_queue.name}", jobs: [1, 2, 3], config:) }

    it 'responds quacks like Sidekiq::UnitOfWork' do
      expect(unit_of_work).to respond_to :acknowledge
      expect(unit_of_work).to respond_to :queue
      expect(unit_of_work).to respond_to :queue_name
      expect(unit_of_work).to respond_to :config
      expect(unit_of_work).to respond_to :job
    end

    it 'should queue into processing' do
      expect(unit_of_work.job).to satisfy do |json|
        job   = JSON.parse(json, symbolize_names: true)
        klass = PerformBulk::Processor.name
        queue = process_queue.name

        job in class: ^klass, queue: ^queue, args: [1, 2, 3]
      end
    end
  end

  describe PerformBulk::Processor do
    let(:processor) { PerformBulk::Processor }
    let(:runner)    { PerformBulk::Runner }
    let(:batch)     {
      [
        { 'class' => 'FooJob', 'args' => [{ 'id' => 1 }] },
        { 'class' => 'BarJob', 'args' => [{ 'id' => 2 }] },
        { 'class' => 'FooJob', 'args' => [{ 'id' => 3 }] },
        { 'class' => 'BazJob', 'args' => [{ 'id' => 4 }] },
      ]
    }

    it 'should queue grouped batches into runner' do
      jid = processor.perform_async(*batch)

      expect(processor.queue).to eq process_queue.name
      expect(processor.jobs.size).to eq 1
      processor.drain

      expect(runner.queue).to eq run_queue.name
      expect(runner.jobs.size).to eq 3

      expect(runner.jobs.first['class']).to eq runner.name
      expect(runner.jobs.first['args']).to eq ['FooJob', [{ 'id' => 1 }, { 'id' => 3 }]]

      expect(runner.jobs.second['class']).to eq runner.name
      expect(runner.jobs.second['args']).to eq ['BarJob', [{ 'id' => 2 }]]

      expect(runner.jobs.third['class']).to eq runner.name
      expect(runner.jobs.third['args']).to eq ['BazJob', [{ 'id' => 4 }]]
    end
  end

  describe PerformBulk::Runner do
    temporary_model :test_job, table_name: nil, base_class: nil do
      include Sidekiq::Job
      include PerformBulk::Job

      def perform(*) = nil
    end

    let(:runner) { PerformBulk::Runner }
    let(:job)    { TestJob }

    context 'default queue' do
      it 'should queue job into queue' do
        jid = runner.perform_async(job.name, [{'bar' => 1}, {'baz' => 2}, {'qux' => 3}])

        expect(runner.queue).to eq run_queue.name
        expect(runner.jobs.size).to eq 1
        runner.drain

        expect(job.jobs.size).to eq 1
        expect(job.jobs.first['queue']).to eq 'default'
      end
    end

    context 'custom queue' do
      before { job.sidekiq_options queue: :test }

      it 'should queue job into custom queue' do
        jid = runner.perform_async(job.name, [{'bar' => 1}, {'baz' => 2}, {'qux' => 3}])

        expect(runner.queue).to eq run_queue.name
        expect(runner.jobs.size).to eq 1
        runner.drain

        expect(job.jobs.size).to eq 1
        expect(job.jobs.first['queue']).to eq 'test'
      end
    end
  end

  describe PerformBulk::Job do
    temporary_model :test_job, table_name: nil, base_class: nil do
      include Sidekiq::Job
      include PerformBulk::Job

      def perform(*) = nil
    end

    let(:job) { TestJob }

    it 'should queue job into bulk queue' do
      expect(job.queue).to eq wait_queue.name
    end
  end
end
