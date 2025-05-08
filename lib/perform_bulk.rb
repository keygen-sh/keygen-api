# frozen_string_literal: true

require 'securerandom'
require 'sidekiq'
require 'sidekiq/capsule'
require 'sidekiq/fetch'

module PerformBulk
  QUEUE_PREFIX  = 'perform_bulk:'
  QUEUE_INGRESS = QUEUE_PREFIX + 'ingress' # the queue used for unbatched bulk jobs
  QUEUE_EGRESS  = QUEUE_PREFIX + 'egress'  # the queue used for batched bulk jobs

  # including PerformBulk::Job allows a Sidekiq::Job to opt into bulk processing,
  # where the bulk fetcher dequeues multiple jobs and batches them into a
  # single job execution, where the job accepts a splat of args.
  #
  # e.g. if we have an existing AuditLog job:
  #
  #   class AuditLogJob
  #     include Sidekiq::Job
  #
  #     def perform(log)
  #       AuditLog.create(log)
  #     end
  #   end
  #
  # but after awhile, this job has high throughput, and we'd greatly benefit
  # from bulk inserting such simple log rows.
  #
  # we can modify it to be a bulk job:
  #
  #   class AuditLogJob
  #     include Sidekiq::Job
  #     include PerformBulk::Job
  #
  #     def perform(*logs)
  #       AuditLog.insert_all(logs)
  #     end
  #   end
  #
  # we can queue jobs normally, but during times of high writes, they'll be
  # batched up and executed accordingly:
  #
  #   25.times { AuditLogJob.perform_async(...) }
  #
  # the above will result in a single job execution, where logs is equal to
  # the args of the 25 batched jobs.
  module Job
    def self.included(klass)
      raise ArgumentError, "cannot be used outside of Sidekiq job (got #{klass.ancestors})" unless
        klass < Sidekiq::Job

      klass.extend ClassMethods

      # NB(ezekg) swap the bulk job's queue over to our capsule's ingress queue in
      #           case our job doesn't ever call .sidekiq_options
      klass.sidekiq_options queue: PerformBulk::QUEUE_INGRESS
    end

    module ClassMethods
      # FIXME(ezekg) there's gotta be a better way to do this?
      def sidekiq_options(...)
        opts = super(...)

        # hijack bulk job to push new jobs to our capsule's ingress queue, and
        # then we'll push to the expected egress queue after batching.
        unless opts['queue'] == PerformBulk::QUEUE_INGRESS
          opts['queue_was'] = opts.delete('queue')
          opts['queue']     = PerformBulk::QUEUE_INGRESS
        end

        opts
      end
    end
  end

  class Processor
    include Sidekiq::Job

    def perform(*batch)
      batch.group_by { _1['class'] }.each do |class_name, job_hashes|
        args = job_hashes.collect { _1['args'] }.reduce(&:concat) # batch args

        Runner.perform_async(class_name, args)
      end
    end
  end

  class Runner
    include Sidekiq::Job

    def perform(class_name, args)
      klass = Object.const_get(class_name)
      queue = klass.sidekiq_options_hash['queue_was'] || 'default'

      klass.set(queue:).perform_async(*args)
    end
  end

  # NB(ezekg) this conforms to the interface of Sidekiq's UnitOfWork struct
  UnitOfWork = Struct.new(:queue, :batch, :config) do
    def queue_name  = queue.delete_prefix('queue:')
    def acknowledge = nil # nothing to do

    # jit-compute underlying egress job
    def job = @job ||= begin
      now = Process.clock_gettime(Process::CLOCK_REALTIME, :millisecond)

      Sidekiq.dump_json(
        'class' => PerformBulk::Processor.name,
        'jid' => SecureRandom.hex(12),
        'queue' => QUEUE_EGRESS,
        'args' => Sidekiq.load_json('[' + batch.join(',') + ']'), # NB(ezekg) optimized single-pass parse
        'created_at' => now,
        'enqueued_at' => now,
        'retry' => true,
      )
    end

    def requeue
      config.redis { |conn| conn.rpush(queue, *batch) }
    end
  end

  class BulkFetch < Sidekiq::BasicFetch
    attr_reader :batch_size

    def initialize(capsule)
      super(capsule)

      @batch_size = capsule.config[:bulk_batch_size]
    end

    def retrieve_work
      batch = Sidekiq.redis { _1.rpop("queue:#{QUEUE_INGRESS}", batch_size) }
      if batch.blank?
        Sidekiq.logger.debug { "no work - sleeping for #{TIMEOUT}" }

        sleep TIMEOUT

        return nil
      end

      Sidekiq.logger.debug { "batch - #{batch}" }

      UnitOfWork.new("queue:#{QUEUE_EGRESS}", batch, config)
    end

    def bulk_requeue(processing)
      return if processing.empty?

      Sidekiq.logger.debug { "requeueing terminated bulk jobs - #{processing}" }

      batches_to_requeue = {}

      processing.each do |unit_of_work|
        batches_to_requeue[unit_of_work.queue] ||= []
        batches_to_requeue[unit_of_work.queue].concat(unit_of_work.batch)
      end

      redis do |conn|
        conn.pipelined do |pipeline|
          batches_to_requeue.each do |queue, batch|
            pipeline.rpush(queue, *batch)
          end
        end
      end

      Sidekiq.logger.info { "pushed #{processing.size} bulk jobs back to redis" }
    rescue => e
      Sidekiq.logger.warn { "failed to requeue #{processing.size} bulk jobs: #{e.message}" }
    end
  end

  def self.bulk_fetch!(config, concurrency: 1, batch_size: 100)
    config.capsule("perform_bulk:ingress") do |cap|
      cap.config[:bulk_batch_size] = batch_size

      cap.queues      = [QUEUE_INGRESS] # TODO(ezekg) would be nice to have per-job queues
      cap.concurrency = concurrency

      # FIXME(ezekg) sidekiq does not support capsule-local config like cap.config[:fetch_class] = BulkFetch
      cap.fetcher = BulkFetch.new(cap)
    end

    config.capsule("perform_bulk:egress") do |cap|
      cap.queues      = [QUEUE_EGRESS]
      cap.concurrency = concurrency
    end
  end

  module CapsuleExtension
    # FIXME(ezekg) hack because sidekiq capsules mutate global config
    def fetcher=(instance)
      @fetcher = instance
    end
  end

  Sidekiq::Capsule.prepend(CapsuleExtension)
end
