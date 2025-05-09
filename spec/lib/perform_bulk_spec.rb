# frozen_string_literal: true

require 'sidekiq/testing'
require 'sidekiq/api'
require 'temporary_tables'
require 'rails_helper'
require 'spec_helper'

require_dependency Rails.root / 'lib' / 'perform_bulk'

module Sidekiq
  module QueueDrain
    refine Sidekiq::Queue do
      def drain
        each do |job|
          klass    = job['class'].constantize
          instance = klass.new
          instance.jid = job['jid']
          instance.perform(*job['args'])
        end
      end
    end
  end

  module QueuePush
    refine Sidekiq::Queue do
      def push(job_or_jobstr)
        job = if job_or_jobstr in String
                Sidekiq.load_json(job_or_jobstr)
              else
                job_or_jobstr
              end

        Sidekiq::Client.new.push(job)
      end
    end
  end
end

describe PerformBulk do
  using Sidekiq::QueueDrain
  using Sidekiq::QueuePush

  let(:wait_queue)    { Sidekiq::Queue.new(PerformBulk::QUEUE_WAITING) }
  let(:process_queue) { Sidekiq::Queue.new(PerformBulk::QUEUE_PROCESSING) }
  let(:run_queue)     { Sidekiq::Queue.new(PerformBulk::QUEUE_RUNNING) }
  let(:default_queue) { Sidekiq::Queue.new('default') }
  let(:test_queue)    { Sidekiq::Queue.new('test') }

  let(:config)  { Sidekiq::Config.new(bulk_batch_size: 100) }
  let(:capsule) { Sidekiq::Capsule.new('perform_bulk/test', config) }

  # we want to test with real queues i.e. against redis
  around do |example|
    Sidekiq::Testing.disable! { example.run }
  end

  after do
    [wait_queue, process_queue, run_queue, default_queue, test_queue].each(&:clear)
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

      expect(process_queue.size).to eq 1
      process_queue.drain

      expect(run_queue.size).to eq 3

      run_queue.each_with_index do |job, i|
        expect(job['class']).to eq runner.name

        # order is not guaranteed so pattern matching helps keep this clean
        case job['args']
        in ['FooJob', args]
          expect(args).to eq [{ 'id' => 1 }, { 'id' => 3 }]
        in ['BarJob', args]
          expect(args).to eq [{ 'id' => 2 }]
        in ['BazJob', args]
          expect(args).to eq [{ 'id' => 4 }]
        end
      end
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
        jid = runner.perform_async(job.name, [{ 'foo' => 0 }, { 'bar' => 1 }, { 'baz' => 2 }, { 'qux' => 3 }])

        expect(run_queue.size).to eq 1
        run_queue.drain

        expect(default_queue.size).to eq 1
        expect(default_queue.first['queue']).to eq 'default'
      end
    end

    context 'custom queue' do
      before { job.sidekiq_options queue: :test }

      it 'should queue job into custom queue' do
        jid = runner.perform_async(job.name, [{ 'foo' => 0 }, { 'bar' => 1 }, { 'baz' => 2 }, { 'qux' => 3 }])

        expect(run_queue.size).to eq 1
        run_queue.drain

        expect(test_queue.size).to eq 1
        expect(test_queue.first['queue']).to eq 'test'
      end
    end
  end

  describe PerformBulk::Job do
    temporary_model :test_job, table_name: nil, base_class: nil do
      include Sidekiq::Job
      include PerformBulk::Job

      def perform(*) = nil
    end

    let(:fetcher)   { PerformBulk::BulkFetch }
    let(:processor) { PerformBulk::Processor }
    let(:runner)    { PerformBulk::Runner }
    let(:job)       { TestJob }

    it 'should queue job into bulk queue' do
      expect(job.queue).to eq wait_queue.name
    end

    context 'with singular args' do
      it 'should perform bulk' do
        expect_any_instance_of(job).to receive(:perform).with(
          'a', 'b', 'c',
          'd', 'e',
        )

        # queue bulk jobs
        job.perform_async('a')
        job.perform_async('b')
        job.perform_async('c')
        job.perform_async('d')
        job.perform_async('e')

        # assert waiting
        expect(wait_queue.size).to eq 5

        # fetch batch
        fetch = fetcher.new(capsule)
        uow   = fetch.retrieve_work

        expect(uow).to_not be nil

        # process batch
        process_queue.push(uow.job)

        expect(process_queue.size).to eq 1
        process_queue.drain

        # run batch
        expect(run_queue.size).to eq 1
        run_queue.drain

        # run bulk job
        expect(default_queue.size).to eq 1
        default_queue.drain
      end
    end

    context 'with multiple args' do
      it 'should perform bulk' do
        expect_any_instance_of(job).to receive(:perform).with(
          [0, 1], [2, 3], [4, 5],
          [6, 7], [8, 9],
        )

        job.perform_async(0, 1)
        job.perform_async(2, 3)
        job.perform_async(4, 5)
        job.perform_async(6, 7)
        job.perform_async(8, 9)
        expect(wait_queue.size).to eq 5

        fetch = fetcher.new(capsule)
        uow   = fetch.retrieve_work
        expect(uow).to_not be nil
        process_queue.push(uow.job)

        expect(process_queue.size).to eq 1
        process_queue.drain

        expect(run_queue.size).to eq 1
        run_queue.drain

        expect(default_queue.size).to eq 1
        default_queue.drain
      end
    end

    context 'with array args' do
      it 'should perform bulk' do
        expect_any_instance_of(job).to receive(:perform).with(
          [0, 1], [2, 3], [4, 5],
          [6, 7], [8, 9],
        )

        job.perform_async([0, 1])
        job.perform_async([2, 3])
        job.perform_async([4, 5])
        job.perform_async([6, 7])
        job.perform_async([8, 9])
        expect(wait_queue.size).to eq 5

        fetch = fetcher.new(capsule)
        uow   = fetch.retrieve_work
        expect(uow).to_not be nil
        process_queue.push(uow.job)

        expect(process_queue.size).to eq 1
        process_queue.drain

        expect(run_queue.size).to eq 1
        run_queue.drain

        expect(default_queue.size).to eq 1
        default_queue.drain
      end
    end

    context 'with hash args' do
      it 'should perform bulk' do
        expect_any_instance_of(job).to receive(:perform).with(
          { 'a' => 0, 'b' => 1 }, { 'a' => 2, 'b' => 3 },
          { 'a' => 4, 'b' => 5 }, { 'a' => 6, 'b' => 7 },
          { 'a' => 8, 'b' => 9 },
        )

        job.perform_async('a' => 0, 'b' => 1)
        job.perform_async('a' => 2, 'b' => 3)
        job.perform_async('a' => 4, 'b' => 5)
        job.perform_async('a' => 6, 'b' => 7)
        job.perform_async('a' => 8, 'b' => 9)
        expect(wait_queue.size).to eq 5

        fetch = fetcher.new(capsule)
        uow   = fetch.retrieve_work
        expect(uow).to_not be nil
        process_queue.push(uow.job)

        expect(process_queue.size).to eq 1
        process_queue.drain

        expect(run_queue.size).to eq 1
        run_queue.drain

        expect(default_queue.size).to eq 1
        default_queue.drain
      end
    end
  end
end
